require 'rubygems'
require 'nokogiri'
require 'uri/http'
require 'mapel'
require 'tempfile'
require 'open-uri'
require 'sanitize'

module Readability
  class Document
    TEXT_LENGTH_THRESHOLD = 25
    RETRY_LENGTH = 250
    
    # Multimedia Scoring
    PIXELS_PER_CHARACTER = 120  # For every PIXELS_PER_CHARACTER pixels in an image, add 1 character to the content score
    IMAGE_SCORE_THRESHOLD = 500
    
    attr_accessor :options, :html

    def initialize(input, options = {})
      @input = input
      @options = options
      @image_score_cache = {}
      make_html
      
      # Defaults
      @options[:tags] ||= %w[div p]
    end

    def make_html
      @html = Nokogiri::HTML(@input, nil, 'UTF-8')
    end

    REGEXES = {
        :unlikelyCandidatesRe => /combx|comment|disqus|foot|header|menu|meta|nav|rss|shoutbox|sidebar|sponsor/i,
        :okMaybeItsACandidateRe => /and|article|body|column|main/i,
        :positiveRe => /article|body|content|entry|hentry|page|pagination|post|text/i,
        :negativeRe => /combx|comment|contact|foot|footer|footnote|link|media|meta|promo|related|scroll|shoutbox|sponsor|tags|widget/i,
        :divToPElementsRe => /<(a|blockquote|dl|div|img|ol|p|pre|table|ul)/i,
        :replaceBrsRe => /(<br[^>]*>[ \n\r\t]*){2,}/i,
        :replaceFontsRe => /<(\/?)font[^>]*>/i,
        :trimRe => /^\s+|\s+$/,
        :normalizeRe => /\s{2,}/,
        :killBreaksRe => /(<br\s*\/?>(\s|&nbsp;?)*){1,}/,
        :videoRe => /http:\/\/(www\.)?(youtube|vimeo)\.com/i
    }

    def content(remove_unlikely_candidates = true)
      @html.css("script, style").each { |i| i.remove }
      
      resolve_and_validate_local_paths!
      
      remove_unlikely_candidates! if remove_unlikely_candidates
      transform_misused_divs_into_paragraphs!
      candidates = score_paragraphs(options[:min_text_length] || TEXT_LENGTH_THRESHOLD)
      best_candidate = select_best_candidate(candidates)
      article = get_article(candidates, best_candidate)
      
      cleaned_article = sanitize(article, candidates, options)
      if remove_unlikely_candidates && get_content_length(article) < (options[:retry_length] || RETRY_LENGTH)
        make_html
        content(false)
      else
        cleaned_article
      end
    end
    
    def resolve_and_validate_local_paths!
      # Resolve a:href, img:src, object:src, embed:src
      @html.css("a,img,object,embed").each do | el |
        ["href", "src"].each do | attribute |
          unless el[attribute].blank?
            el[attribute] = resolve_url(el[attribute])
            el[attribute] = "" unless validate_url(el[attribute])
          end
        end
      end
    end
    
    def validate_url(url)
      uri = URI.parse url
      if !%w[http https].include?(uri.scheme)
        raise
      end
      if [:scheme, :host].any? { |i| uri.send(i).blank? }
        raise
      end
      true
    rescue
      false
    end
    
    def resolve_url(url)
      return "" if options[:source_url].blank?
      
      source = URI.parse options[:source_url]
      source.normalize!
      
      uri = URI.parse url
      uri.normalize!
      uri = source + uri if uri.relative?
      uri.to_s
    rescue
      ""
    end
    
    def get_content_length(node)
      # Originally this method looks at the number of characters in a node, but we're going to expand it to 
      # take into consideration the dimensions of images and embeds, as well.
      
      node_score = 0
      text_contribution = node.text.strip.length
      
      image_contribution = 0
      embed_contribution = 0
      
      # Requires global src URL's!
      if options[:score_multimedia]
        
        # Image contributions
        node.css("img").each do | image |
          
          # download image and calculate score, if necessary
          if !image[:src].blank? && (image[:width].blank? || image[:height].blank?)
            # Have we seen this image already?
            if @image_score_cache[image[:src]]
              debug("Pulled dimensions from cache")
              image["width"] = @image_score_cache[image[:src]]["width"]
              image["height"] = @image_score_cache[image[:src]]["height"]
            else
              debug("Downloading image to score: #{image[:src]}")
              image_fp = Tempfile.new "readability"
              image_fp.syswrite open(image[:src]).read
              image_info = Mapel.info image_fp.path
              if image_info[:dimensions][0].to_i > 0 && image_info[:dimensions][1].to_i > 0
                image["width"] = image_info[:dimensions][0].to_s
                image["height"] = image_info[:dimensions][1].to_s
                @image_score_cache[image[:src]] = {}
                @image_score_cache[image[:src]]["width"] = image["width"]
                @image_score_cache[image[:src]]["height"] = image["height"]
              end
            end
          end
          
          if image[:width] and image[:height]
            local_contribution = (image[:width].to_i * image[:height].to_i) / PIXELS_PER_CHARACTER
            image_contribution += local_contribution if local_contribution > IMAGE_SCORE_THRESHOLD  # Don't count small images
          end
        end
        
        # Embed contributions
        node.css("embed").each do | embed |
          if embed[:width] && embed[:height]
            embed_contribution += (embed[:width].to_i * embed[:height].to_i) / PIXELS_PER_CHARACTER
          end
        end
        
        debug "#{node[:class]}#{node[:id]} image contribution: #{image_contribution}, embed contribution: #{embed_contribution}"
        
        node_score += image_contribution
        node_score += embed_contribution
      end
      node_score
    rescue Exception => e
      debug "In get_content_length rescue, #{$!}, #{e.backtrace.first.inspect}"
      node.text.strip.length
    end

    def get_article(candidates, best_candidate)
      # Now that we have the top candidate, look through its siblings for content that might also be related.
      # Things like preambles, content split by ads that we removed, etc.

      sibling_score_threshold = [10, best_candidate[:content_score] * 0.2].max
      output = Nokogiri::XML::Node.new('div', @html)
      best_candidate[:elem].parent.children.each do |sibling|
        append = false
        append = true if sibling == best_candidate[:elem]
        append = true if candidates[sibling] && candidates[sibling][:content_score] >= sibling_score_threshold

        if sibling.name.downcase == "p"
          link_density = get_link_density(sibling)
          node_content = sibling.text
          node_length = get_content_length sibling

          if node_length > 80 && link_density < 0.25
            append = true
          elsif node_length < 80 && link_density == 0 && (node_content =~ /\.( |$)/ || options[:score_multimedia])
            append = true
          end
        end

        if append
          sibling.name = "div" unless %w[div p].include?(sibling.name.downcase)
          output << sibling
        end
      end

      output
    end

    def select_best_candidate(candidates)
      sorted_candidates = candidates.values.sort { |a, b| b[:content_score] <=> a[:content_score] }

      debug("Top 5 canidates:")
      sorted_candidates[0...5].each do |candidate|
        debug("Candidate #{candidate[:elem].name}##{candidate[:elem][:id]}.#{candidate[:elem][:class]} with score #{candidate[:content_score]}")
      end

      best_candidate = sorted_candidates.first || { :elem => @html.css("body").first, :content_score => 0 }
      debug("Best candidate #{best_candidate[:elem].name}##{best_candidate[:elem][:id]}.#{best_candidate[:elem][:class]} with score #{best_candidate[:content_score]}")

      best_candidate
    end

    def get_link_density(elem)
      link_length = elem.css("a").map {|i| i.text}.join("").length
      text_length = [get_content_length(elem), 1].max
      link_length / text_length.to_f
    end

    def score_paragraphs(min_text_length)
      candidates = {}
      @html.css("p,td,li").each do |elem|
        parent_node = elem.parent
        grand_parent_node = parent_node.respond_to?(:parent) ? parent_node.parent : nil

        # If this paragraph is less than 25 characters, don't even count it.
        next if get_content_length(elem) < min_text_length

        candidates[parent_node] ||= score_node(parent_node)
        candidates[grand_parent_node] ||= score_node(grand_parent_node) if grand_parent_node

        content_score = 1
        content_score += elem.text.split(',').length
        content_score += [(get_content_length(elem) / 100).to_i, 3].min

        candidates[parent_node][:content_score] += content_score
        candidates[grand_parent_node][:content_score] += content_score / 2.0 if grand_parent_node
      end

      # Scale the final candidates score based on link density. Good content should have a
      # relatively small link density (5% or less) and be mostly unaffected by this operation.
      candidates.each do |elem, candidate|
        candidate[:content_score] = candidate[:content_score] * (1 - get_link_density(elem))
      end

      candidates
    end

    def class_weight(e)
      weight = 0
      if e[:class] && e[:class] != ""
        if e[:class] =~ REGEXES[:negativeRe]
          weight -= 25
        end

        if e[:class] =~ REGEXES[:positiveRe]
          weight += 25
        end
      end

      if e[:id] && e[:id] != ""
        if e[:id] =~ REGEXES[:negativeRe]
          weight -= 25
        end

        if e[:id] =~ REGEXES[:positiveRe]
          weight += 25
        end
      end

      weight
    end

    def score_node(elem)
      content_score = class_weight(elem)
      case elem.name.downcase
        when "div":
          content_score += 5
        when "blockquote":
          content_score += 3
        when "form":
          content_score -= 3
        when "th":
          content_score -= 5
      end
      { :content_score => content_score, :elem => elem }
    end

    def debug(str)
      puts str if options[:debug]
    end

    def remove_unlikely_candidates!
      @html.css("*").each do |elem|
        str = "#{elem[:class]}#{elem[:id]}"
        if str =~ REGEXES[:unlikelyCandidatesRe] && str !~ REGEXES[:okMaybeItsACandidateRe] && elem.name.downcase != 'body'
          debug("Removing unlikely candidate - #{str}")
          elem.remove
        end
      end
    end

    def transform_misused_divs_into_paragraphs!
      @html.css("*").each do |elem|
        if elem.name.downcase == "div"
          # transform <div>s that do not contain other block elements into <p>s
          if elem.inner_html !~ REGEXES[:divToPElementsRe]
            debug("Altering div(##{elem[:id]}.#{elem[:class]}) to p");
            elem.name = "p"
          end
        else
          # wrap text nodes in p tags
#          elem.children.each do |child|
#            if child.text?
##              debug("wrapping text node with a p")
#              child.swap("<p>#{child.text}</p>")
#            end
#          end
        end
      end
    end

    def sanitize(node, candidates, options = {})
      node.css("h1, h2, h3, h4, h5, h6").each do |header|
        header.remove if class_weight(header) < 0 || get_link_density(header) > 0.33
      end

      node.css("form, object, iframe, embed").each do |elem|
        elem.remove unless @options[:tags].include?(elem.node_name.downcase)
      end

      # remove empty <p>, <div> tags
      node.css("p,div").each do |elem|
        if elem.content.strip.empty? and elem.css("img,embed,object").length == 0
          debug "looks like empty content: removing #{elem.node_name.downcase}##{elem[:id]}.#{elem[:class]}"
          elem.remove
        end
      end

      # Conditionally clean <table>s, <ul>s, and <div>s
      node.css("table, ul, div").each do |el|
        weight = class_weight(el)
        content_score = candidates[el] ? candidates[el][:content_score] : 0
        name = el.name.downcase

        if weight + content_score < 0
          el.remove
          debug("Conditionally cleaned #{name}##{el[:id]}.#{el[:class]} with weight #{weight} and content score #{content_score} because score + content score was less than zero.")
        elsif el.text.count(",") < 10
          counts = %w[p img li a embed input].inject({}) { |m, kind| m[kind] = el.css(kind).length; m }
          counts["li"] -= 100

          content_length = get_content_length el
          link_density = get_link_density(el)
          to_remove = false
          reason = ""
          
          if options[:score_multimedia]
            if counts["input"] > (counts["p"] / 3).to_i
              reason = "less than 3x <p>s than <input>s"
              to_remove = true
            elsif content_length < (options[:min_text_length] || TEXT_LENGTH_THRESHOLD) && (counts["img"] == 0)
              reason = "too short a content length without a single image"
              to_remove = true
            elsif weight < 25 && link_density > 0.2
              reason = "too many links for its weight (#{weight})"
              to_remove = true
            elsif weight >= 25 && link_density > 0.5
              reason = "too many links for its weight (#{weight})"
              to_remove = true
            elsif (counts["embed"] == 1 && content_length < 75)
              reason = "<embed>s with too short a content length, or too many <embed>s"
              to_remove = true
            end
          else
            if counts["img"] > counts["p"]
              reason = "too many images"
              to_remove = true
            elsif counts["li"] > counts["p"] && name != "ul" && name != "ol"
              reason = "more <li>s than <p>s"
              to_remove = true
            elsif counts["input"] > (counts["p"] / 3).to_i
              reason = "less than 3x <p>s than <input>s"
              to_remove = true
            elsif content_length < (options[:min_text_length] || TEXT_LENGTH_THRESHOLD) && (counts["img"] == 0)
              reason = "too short a content length without a single image"
              to_remove = true
            elsif weight < 25 && link_density > 0.2
              reason = "too many links for its weight (#{weight})"
              to_remove = true
            elsif weight >= 25 && link_density > 0.5
              reason = "too many links for its weight (#{weight})"
              to_remove = true
            elsif (counts["embed"] == 1 && content_length < 75)
              reason = "<embed>s with too short a content length, or too many <embed>s"
              to_remove = true
            end
          end
          
          if to_remove
            debug("Conditionally cleaned #{name}##{el[:id]}.#{el[:class]} with weight #{weight} and content score #{content_score} because it has #{reason}.")
            el.remove
          end
        end
      end

      # We'll sanitize all elements using a whitelist
      # base_whitelist = @options[:tags]

      # Use a hash for speed (don't want to make a million calls to include?)
      # whitelist = Hash.new
      # base_whitelist.each {|tag| whitelist[tag] = true }
      # ([node] + node.css("*")).each do |el|
      #   # If element is in whitelist, delete all its attributes
      #   if whitelist[el.node_name]
      #     el.attributes.each { |a, x| el.delete(a) unless (@options[:attributes] && @options[:attributes].include?(a.to_s)) || 
      #                                                       (options[:attributes_by_tag][el.node_name] && options[:attributes_by_tag][el.node_name].include?(a.to_s)) }
      #   # Otherwise, replace the element with its contents
      #   else
      #     el.swap(el.text)
      #   end
      # end
      
      # Image transformer
      image_transformer = lambda do |env|
        node = env[:node]
        node_name = env[:node_name]
        
        return if node_name != "img" or node["width"].nil? or node["height"].nil?
        
        # Get score
        image_score = (node["width"].to_i * node["height"].to_i) / PIXELS_PER_CHARACTER
        
        if image_score < IMAGE_SCORE_THRESHOLD
          Sanitize.clean_node!(node, Sanitize::Config::RESTRICTED)
          nil
        end
      end
      
      # Embed Transformer
      embed_transformer = lambda do |env|
        node      = env[:node]
        node_name = env[:node_name]
        parent    = node.parent

        return nil unless (node_name == 'param' || node_name == 'embed') &&
            parent.name.to_s.downcase == 'object'

        # Set allowscriptaccess to never
        script_param_node = parent.search('param[@name="allowscriptaccess"]')
        unless script_param_node.nil?
          script_param_node.each do |el|
            el["value"] = "never"
          end
        end

        # Cap width to 550
        parent["width"] = [parent["width"].to_i, 550].min.to_s
        embed = parent.search('embed').first if parent.search('embed')
        embed["width"] = [embed["width"].to_i, 550].min.to_s

        Sanitize.clean_node!(parent, {
          :elements   => ['embed', 'object', 'param'],
          :attributes => {
            'embed'  => ['allowfullscreen', 'height', 'src', 'type', 'width'],
            'object' => ['height', 'width'],
            'param'  => ['name', 'value']
          }
        })

        {:whitelist_nodes => [node, parent]}
      end
      
      allowed_elements = @options[:tags]
      allowed_attributes = @options[:attributes_by_tag]
      allowed_protocols = {
        'a'   => {'href' => ['http', 'https']},
        'img' => {'src'  => ['http', 'https']}
      }
      add_attributes = {
        "a"       => {"rel"=>"nofollow"},
        "embed"   => {"allowscriptaccess"=>"never"}
      }
      return (Sanitize.clean node.to_html, :elements => allowed_elements, :protocols => allowed_protocols, :attributes => allowed_attributes, 
                  :add_attributes => add_attributes, :transformers => [embed_transformer, image_transformer]).gsub(/[\r\n\f]+/, "\n" ).gsub(/[\t ]+/, " ").gsub(/&nbsp;/, " ")
      
      # Get rid of duplicate whitespace
      # node.to_html.gsub(/[\r\n\f]+/, "\n" ).gsub(/[\t ]+/, " ").gsub(/&nbsp;/, " ")
    end
    
  end
end
