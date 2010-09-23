# 
# t.string   "media_category"
# t.string   "thumbnail_small",           :default => ""
# t.integer  "thumbnail_small_width",     :default => 0
# t.integer  "thumbnail_small_height",    :default => 0
# t.string   "thumbnail_full",            :default => ""
# t.integer  "thumbnail_full_width",      :default => 0
# t.integer  "thumbnail_full_height",     :default => 0
# t.text     "introduction"
# t.text     "html_body"
# t.string   "title",                     :default => ""
# t.string   "like_title",                :default => ""
# t.string   "source_url"
# t.string   "shortened_url",             :default => ""
# t.boolean  "show_link",                 :default => true
# t.boolean  "is_cloaked",                :default => false
# t.integer  "like_count",                :default => 0
# t.integer  "weighted_score",            :default => 0
# t.integer  "user_id",                                      :null => false
# t.datetime "created_at"
# t.datetime "updated_at"
# t.string   "slug"
# t.string   "thumbnail_page"
# t.string   "thumbnail_page_width"
# t.string   "thumbnail_page_height"
# t.string   "thumbnail_thumb"
# t.string   "thumbnail_square"
# t.string   "thumbnail_tiny"
# t.boolean  "image_processing_started",  :default => false
# t.boolean  "image_processing_finished", :default => false
# t.boolean  "remote_url_scraped",        :default => false
# 


require 'open-uri'
require 'tempfile'
require 'aws/s3'
require 'timeout'

class Page < ActiveRecord::Base
  belongs_to :user
  
  has_many :page_votes
  
  validates_format_of_url   :source_url,    :unless => Proc.new { |page| page.source_url.blank? }
  validates_presence_of     :title
  validates_associated      :user
  
  validates_numericality_of :thumbnail_small_width, :greater_than_or_equal_to=>1, :allow_nil=>true,   :unless => Proc.new { |page| page.thumbnail_small.blank? }
  validates_numericality_of :thumbnail_small_height, :greater_than_or_equal_to=>1, :allow_nil=>true,  :unless => Proc.new { |page| page.thumbnail_small.blank? }
  
  validates_numericality_of :thumbnail_full_width, :greater_than_or_equal_to=>1, :allow_nil=>true,    :unless => Proc.new { |page| page.thumbnail_full.blank? }
  validates_numericality_of :thumbnail_full_height, :greater_than_or_equal_to=>1, :allow_nil=>true,   :unless => Proc.new { |page| page.thumbnail_full.blank? }
  
  # Will_paginate
  cattr_reader :per_page
  @@per_page = 30 # this is the default anyway
  
  # We'll check the state of the object to make sure these aren't run on updates
  # before_save :scrape_source_url
  # before_save :process_images # we'll do this in a background process
  before_save :set_slug
  
  # before_save :queue_image_processing
  # def queue_image_processing
  #   unless self.image_processing_started or self.image_processing_finished
  #     # Add processing request to queue
  #     
  #   end
  # end
  
  def set_slug
    if self.slug.blank?
      # Some non-word characters were being included in the slug. This was screwing up voting later on.
      self.slug = self.title.to_url.scan(/\w+/).join("-") unless self.title.blank?
    end
  end
  
  def to_param
    "#{self.id}-#{self.slug}"
  end
  
  # Lookup of permissions -> editable attributes
  EDIT_PERMISSIONS = {
    :god => %w[media_category thumbnail_small thumbnail_small_width thumbnail_small_height thumbnail_full thumbnail_full_width thumbnail_full_height introduction html_body title like_title source_url shortened_url show_link is_cloaked like_count weighted_score user_id created_at updated_at slug],
    :admin => %w[media_category thumbnail_small thumbnail_small_width thumbnail_small_height thumbnail_full thumbnail_full_width thumbnail_full_height introduction html_body title like_title source_url shortened_url show_link is_cloaked like_count weighted_score slug],
    :editor => %w[media_category introduction html_body title source_url show_link],
    :owner => %w[introduction title]
  }
  
  # ONLY CALL IN BG_PROCESSOR
  def process_images
    
    return if self.image_processing_started
    
    # Even if there's no body mark the object as processed
    self.image_processing_started = true
    
    return if self.html_body.blank?
    
    add_thumbnail_for_youtube_embeds
    
    # Setup S3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => S3Keys::S3Config.access_key_id,
      :secret_access_key => S3Keys::S3Config.secret_access_key
    )
    s3_bucket = S3Keys::S3Config.bucket
    
    # For every image
    parsed_source = Nokogiri::HTML(self.html_body)
    parsed_source.css('img').each do |img|
      # Don't re-convert images in our bucket
      unless img["src"].blank? or img["src"] =~ Regexp.new("^http\\:\\/\\/#{s3_bucket}\\.s3\\.amazonaws\\.com\\/(page_images|page_thumbs)", true)
        
        # Setup tmp files
        tmp_full = Tempfile.new "tmp_thumb"   # Original
        tmp_page = Tempfile.new "tmp_thumb"   # 550x
        
        # Grab remote
        begin
          tmp_full.syswrite open(img["src"]).read
        rescue
          puts "Could not find url: #{img["src"]}"
          # logger.error puts "Could not find url: #{img["src"]}"
          # debug
          
          # Don't attempt to process an invalid image
          next
        end
        
        # Get size
        source_info = Mapel.info tmp_full.path
        source_width = source_info[:dimensions][0]
        source_height = source_info[:dimensions][1]
        
        img["width"] = source_width.to_s
        img["height"] = source_height.to_s
        
        # Thumbnail generation
        make_thumbnail(img["src"], tmp_full, s3_bucket, source_info) if self.thumbnail_full.blank?
        
        # Other thumbnail options:
        #   Iterate through website images, pick the largest with "logo" in the filename, or class/id if not in the filename
        #   use the biggest image on the page
        #   use the favicon
        #   use a fake website screenshot.. (later, a real website screenshot?)
        
        # Resize if necessary
        if source_width > 550
          Mapel.render(tmp_full.path).resize("550x").to(tmp_page.path).run
        else
          FileUtils.cp tmp_full.path, tmp_page.path
        end
        
        # Generate new name
        img_name_base = SecureRandom.hex(10)
        img_name_full = "page_images/#{img_name_base}.#{source_info[:format].downcase}"
        img_name_page = "page_images/#{img_name_base}_page.#{source_info[:format].downcase}"
        
        puts "Uploading #{img["src"]} image to S3 as http://#{s3_bucket}.s3.amazonaws.com/#{img_name_page}"
        # logger.warn "Uploading #{img["src"]} image to S3 as http://#{s3_bucket}.s3.amazonaws.com/#{img_name_page}"
        # debug
        
        # Copy files to S3
        AWS::S3::S3Object.store img_name_page, tmp_page, s3_bucket, :access => :public_read
        AWS::S3::S3Object.store img_name_full, tmp_full, s3_bucket, :access => :public_read
        
        new_width = [source_width, 550].min
        new_height = ((source_height / source_width.to_f) * new_width).to_i
        
        # Update tag
        img["src"] = "http://#{s3_bucket}.s3.amazonaws.com/#{img_name_page}"
        img["width"] = new_width.to_s
        img["height"] = new_height.to_s
      end
    end
    
    self.html_body = parsed_source.css("body").first.inner_html
    # Done!
    self.image_processing_finished = true
  rescue Exception => e
    puts "in process_images #{$!}, #{e.backtrace.inspect}"
    # logger.warn "in process_images #{$!}, #{e.backtrace.first.inspect}"
    # debug
  end
  
  
  def sanitize_user_html(unsafe_html)
    self.html_body = sanitize(unsafe_html)
    self.remote_url_scraped = true
  end
  
  
  def scrape_source_url
    # Try to extract some useful content from the remote URL
    
    return if self.source_url.blank? or self.remote_url_scraped
    
    # Mark as finished, even if we bail out due to an error
    self.remote_url_scraped = true
    
    # Only run when there are empty fields
    return unless self.html_body.blank? or self.title.blank? or self.thumbnail_full.blank?
    
    # Special URL's
    unless self.source_url.blank?
      # Youtube
      if self.source_url =~ /http:\/\/(www\.)?(youtube)\.com\/watch?/i
        # Get video info
        video_id = CGI.parse(URI.parse(self.source_url).query)["v"].first
        video_metadata = Nokogiri::XML open("http://gdata.youtube.com/feeds/api/videos/#{video_id}").read
      
        # Update model fields
        self.introduction = video_metadata.xpath("//media:description").first.content
        self.html_body = <<-eos
          <object width="550" height="413">
            <param name="movie" value="http://www.youtube.com/v/#{video_id}?fs=1&amp;hl=en_US"></param>
            <param name="allowFullScreen" value="true"></param>
            <param name="allowscriptaccess" value="never"></param>
            <embed src="http://www.youtube.com/v/#{video_id}?fs=1&amp;hl=en_US" type="application/x-shockwave-flash"
              allowscriptaccess="never" allowfullscreen="true" width="550" height="413"></embed>
          </object><br/>
          <img style="display:none;" src="http://img.youtube.com/vi/#{video_id}/0.jpg" />
        eos
        return
      end
      # Img
      if self.source_url.index /\.(gif|tiff|png|jpeg|jpg|bmp)$/i
        self.html_body = "<p><a href='#{self.source_url}'><img src='#{self.source_url}'/></a></p>"
        # Skip the rest, there's nothing else we can do
        return true
      end
      # Other
      if self.source_url.index /\.(pdf|ps)$/i
        self.html_body = "" # We'll link back to this object automatically
        return true
      end
    end
    
    # Get HTML source
    begin
        raw_html = open(self.source_url).read
    rescue
      logger.error "in scrape_source_url 1 #{$!}"
      return
    end
    
    # Body
    begin
      
      attributes_by_tag = {
        :all => %w[src href],
        "img" => %w[width height],
        "embed" => %w[src type allowfullscreen width height],
        "object" => %w[width height],
        "param" => %w[name value]
      }
      readability_doc = Readability::Document.new raw_html, :score_multimedia=>true, :source_url=>self.source_url, :debug => true,
                              :tags=>%w[img div p strong b em i u h1 h2 h3 h4 h5 h6 ul ol li a br object embed param], :attributes_by_tag=>attributes_by_tag
      
      # Special cleaning
      parsed_doc = Nokogiri::HTML readability_doc.content
      
      # Fix embeds - set allowscriptaccess in both the param and embed tags
      parsed_doc.css("embed").each do |el|
        el["allowscriptaccess"] = "none"
      end
      parsed_doc.css("param").each do |el|
        el.remove unless %w[movie allowfullscreen type src].include?(el["name"].downcase)
      end
      
      # Add nofollow to links
      parsed_doc.css("a").each do |el|
        el["rel"] = "nofollow"
      end
      
      # Update html_body
      self.html_body ||= parsed_doc.css("body").first.inner_html
    rescue Exception => e
      logger.warn "in scrape_source_url #{$!}, #{e.backtrace.inspect}"
      return
    end
    
    # Title
    begin
      if self.title.blank?
        self.title = Nokogiri::HTML(raw_html).css('title').first.try :content
      end
    rescue
      logger.error "in scrape_source_url 3 #{$!}"
      return
    end
  end
  
  
  def add_thumbnail_for_youtube_embeds
    
    return if self.html_body.blank?
    
    # Assumes the page source is available in html_body
    parsed_doc = Nokogiri::HTML self.html_body
    
    # If the post contains a youtube video and no other images, append one
    if parsed_doc and parsed_doc.css("embed,object").length>0 and parsed_doc.css("img").length == 0
      
      # Check for youtube
      embeds = parsed_doc.css("embed,object").each do |el|
        if el["src"] and el["src"] =~ /http:\/\/(www\.)?(youtube)\.com\//i
          # Get video ID, append image
          # After appending our first thumbnail, break
          video_id = el["src"].split("?").first.split("/").last.split("&").first
          
          # If it's a builder page, add an image widget
          if self.created_with_builder
            # Handle Builder V1
            root_divs = parsed_doc.xpath("/html/body/div")
            if root_divs.length == 1 and root_divs.first["class"].strip.downcase=="builder_container_v1"
              img_widget = Nokogiri::XML::DocumentFragment.parse("<span class='builder_image_widget'><img class='builder_val' src='http://img.youtube.com/vi/#{video_id}/0.jpg' /></span>")
              root_divs.first.children.last.add_next_sibling img_widget
              self.html_body = root_divs.first.to_html
            end
          else
            self.html_body += "<img src='http://img.youtube.com/vi/#{video_id}/0.jpg' />"
          end
          break
        end
      end
    end
  rescue
    puts "In rescue in add_thumbnail_for_youtube_embeds"
    # logger.warn "In rescue in add_thumbnail_for_youtube_embeds"
    # debug
  end
  
  
  def calculate_weighted_score!
    # Ranking algorithm as described in RAILS_SETUP_NOTES
    
    # Ts => Time, in Seconds, since 12:00am Sept. 1st
    epoch = Time.local 2010, "sep", 1, 0, 0, 0
    t_s = self.created_at - epoch
    
    # log_b8( like_count )
    weighted_votes = Math.log(self.like_count)/Math.log(8)
    
    # Ts + 45000 * log_b8( like_count )
    self.weighted_score = t_s + 45000 * weighted_votes
    self.save
  end
  
  # 
  # Facebook Open Graph
  
  def og_title
    return self.like_title unless self.like_title.blank?
    return self.title unless self.title.blank?
    nil
  end
  
  def og_image
    return self.thumbnail_square unless self.thumbnail_square.blank?
    nil
  end
  
  def og_url
    return self.shortened_url unless self.shortened_url.blank?
    nil
  end
  
  def og_description
    return self.introduction unless self.introduction.blank?
    nil
  end
  
  
  private
  
    # Caller is responsible for unlinking tmp_full!
    # tmp_full is a temporary file containing the source image
    def make_thumbnail(url, tmp_full, s3_bucket, source_info)
      
      logger.warn "In make_thumbnail, making #{url} the page's thumbnail. info object: #{source_info.inspect}"
      
      # Temp files
      tmp_page = Tempfile.new "tmp_thumb"     # 550' width, maintain ratio
      tmp_small = Tempfile.new "tmp_thumb"    # 100' width, maintain ratio
      tmp_thumb = Tempfile.new "tmp_thumb"    # 100' width, crop 70' height, gravity center
      tmp_square = Tempfile.new "tmp_thumb"   # 75'x75' square, crop gravity center (For use with facebook likes)
      tmp_tiny = Tempfile.new "tmp_thumb"     # 30'x30' square, cropy gravity center  
      
      source_width = source_info[:dimensions][0]
      source_height = source_info[:dimensions][1]
      
      puts "thumbnail dimensions: #{source_width}x#{source_height}"
      # logger.warn "thumbnail dimensions: #{source_width}x#{source_height}"
      # debug
      
      return unless source_width && source_height && source_width >= 75 && source_height >= 75
      
      # Processing
      if source_width > 550
        Mapel.render(tmp_full.path).resize("550x").to(tmp_page.path).run
      else
        FileUtils.cp tmp_full.path, tmp_page.path
      end
      
      if source_width > 100
        Mapel.render(tmp_full.path).resize("100x").to(tmp_small.path).run
        Mapel.render(tmp_full.path).resize("100x").crop("x70").gravity("center").to(tmp_thumb.path).run
      else
        FileUtils.cp tmp_full.path, tmp_small.path
        Mapel.render(tmp_full.path).crop("x70").gravity("center").to(tmp_thumb.path).run
      end
      
      Mapel.render(tmp_full.path).resize("75x").crop("x75").gravity("center").to(tmp_square.path).run
      Mapel.render(tmp_full.path).resize("30x").crop("x30").gravity("center").to(tmp_tiny.path).run
      
      # Generate remote names
      img_name_base = SecureRandom.hex(10)
      img_name_full =   "page_thumbs/#{img_name_base}.#{source_info[:format].downcase}"
      img_name_page =   "page_thumbs/#{img_name_base}_page.#{source_info[:format].downcase}"
      img_name_small =  "page_thumbs/#{img_name_base}_small.#{source_info[:format].downcase}"
      img_name_thumb =  "page_thumbs/#{img_name_base}_thumb.#{source_info[:format].downcase}"
      img_name_square = "page_thumbs/#{img_name_base}_square.#{source_info[:format].downcase}"
      img_name_tiny =   "page_thumbs/#{img_name_base}_tiny.#{source_info[:format].downcase}"
      
      logger.warn "Uploading Thumbnail to S3 as http://#{s3_bucket}.s3.amazonaws.com/#{img_name_full}"
      
      # POST to S3
      # S3 must be setup by this point
      AWS::S3::S3Object.store img_name_full, tmp_full, s3_bucket, :access => :public_read
      AWS::S3::S3Object.store img_name_page, tmp_page, s3_bucket, :access => :public_read
      AWS::S3::S3Object.store img_name_small, tmp_small, s3_bucket, :access => :public_read
      AWS::S3::S3Object.store img_name_thumb, tmp_thumb, s3_bucket, :access => :public_read
      AWS::S3::S3Object.store img_name_square, tmp_square, s3_bucket, :access => :public_read
      AWS::S3::S3Object.store img_name_tiny, tmp_tiny, s3_bucket, :access => :public_read
      
      # Path prefixes
      s3_path_prefix = "http://#{s3_bucket}.s3.amazonaws.com/"
      
      # Update thumbnail fields
      self.thumbnail_full = s3_path_prefix + img_name_full
      self.thumbnail_full_width = source_width
      self.thumbnail_full_height = source_height
      
      img_page_info = Mapel.info tmp_page.path
      
      self.thumbnail_page = s3_path_prefix + img_name_page
      self.thumbnail_page_width = img_page_info[:dimensions][0]
      self.thumbnail_page_height = img_page_info[:dimensions][1]
      
      img_small_info = Mapel.info tmp_small.path
      
      self.thumbnail_small = s3_path_prefix + img_name_small
      self.thumbnail_small_width = img_small_info[:dimensions][0]
      self.thumbnail_small_height = img_small_info[:dimensions][1]
      
      self.thumbnail_thumb = s3_path_prefix + img_name_thumb
      self.thumbnail_square = s3_path_prefix + img_name_square
      self.thumbnail_tiny = s3_path_prefix + img_name_tiny

    rescue
      # logger.error "in make_thumbnail: #{$!}"
      # debug
      puts "in make_thumbnail: #{$!}"
    end
    
    # Return "safe" HTML - only permitted builder tags
    def sanitize(unsafe_html)
      unsafe = Nokogiri::HTML unsafe_html
      root_divs = unsafe.xpath("/html/body/div")
      return "" unless root_divs.length == 1
      
      if (root_divs.first["class"]=="builder_container_v1")
        
        # Specify this page is created with Builder
        self.created_with_builder = true
        
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
        
        # Sanitize config
        allowed_classnames = %w[builder_container_v1 builder_h1_widget builder_h2_widget builder_h3_widget builder_paragraph_widget builder_image_widget builder_embed_widget builder_val_wrapper builder_val]
        allowed_elements = %w[span div h1 h2 h3 p img embed object param]
        allowed_attributes = {
          :all      => %w[class],
          "img"     => %w[src width height],
          "param"   => %w[name value]
        }
        allowed_protocols = {
          'a'   => {'href' => ['http', 'https']},
          'img' => {'src'  => ['http', 'https']}
        }
        add_attributes = {
          "a"       => {"rel"=>"nofollow"},
          "embed"   => {"allowscriptaccess"=>"never"}
        }
        scrubbed = Sanitize.clean unsafe_html, :elements => allowed_elements, :protocols => allowed_protocols, :attributes => allowed_attributes,
                      :add_attributes => add_attributes, :transformers => [embed_transformer]
        
        # Filter classnames
        safe = Nokogiri::HTML scrubbed
        safe.css("*").each do |el|
          unless el["class"].blank?
            clean_class = []
            el["class"].split(' ').each do |classname|
              if allowed_classnames.include? classname
                clean_class.push classname
              end
            end
            el["class"] = clean_class.join " "
          end
        end
        
        return safe.css("body").first.inner_html
      end
      return ""
    end
end