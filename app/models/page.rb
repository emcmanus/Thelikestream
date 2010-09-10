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
  
  acts_as_url :title, :url_attribute => :slug, :only_when_blank => true
  
  validates_format_of_url   :source_url
  validates_presence_of     :title
  validates_associated      :user
  
  validates_numericality_of :thumbnail_small_width, :greater_than_or_equal_to=>1, :allow_nil=>true,   :unless => Proc.new { |page| page.thumbnail_small.blank? }
  validates_numericality_of :thumbnail_small_height, :greater_than_or_equal_to=>1, :allow_nil=>true,  :unless => Proc.new { |page| page.thumbnail_small.blank? }
  
  validates_numericality_of :thumbnail_full_width, :greater_than_or_equal_to=>1, :allow_nil=>true,    :unless => Proc.new { |page| page.thumbnail_full.blank? }
  validates_numericality_of :thumbnail_full_height, :greater_than_or_equal_to=>1, :allow_nil=>true,   :unless => Proc.new { |page| page.thumbnail_full.blank? }
  
  before_save :scrape_source_url, :unless => :remote_url_scraped
  before_save :process_images,    :unless => :image_processing_started
  
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
  
  
  def process_images
    
    return if self.html_body.blank?
    
    # Otherwise, mark as started
    self.image_processing_started = true
    
    # Setup S3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => '13WQ80HKRY1EJA7SH9R2',
      :secret_access_key => '67IJS5Tc8VQLrrougD2AJQBFyw3B2YER6dAHXvwj'
    )
    if RAILS_ENV == "production"
      s3_bucket = 'likestream'
    else
      s3_bucket = 'likestream-development'
    end
    
    # For every image
    imgs = Nokogiri::HTML(self.html_body).css('img')
    imgs.each do |img|
      unless img[:src].blank?
        
        # Setup tmp files
        tmp_full = Tempfile.new "tmp_thumb"   # Original
        tmp_page = Tempfile.new "tmp_thumb"   # 550x
        
        # Grab remote
        tmp_full.syswrite open(img[:src]).read
        
        # Get size
        source_info = Mapel.info tmp_full.path
        source_width = source_info[:dimensions][0]
        source_height = source_info[:dimensions][1]
        
        # Thumbnail generation
        make_thumbnail(img[:src], tmp_full, s3_bucket, source_info) if self.thumbnail_full.blank?
        
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
        
        logger.warn "Uploading #{img[:src]} image to S3 as http://#{s3_bucket}.s3.amazonaws.com/#{img_name_page}"
        
        # Copy files to S3
        AWS::S3::S3Object.store img_name_page, tmp_page, s3_bucket, :access => :public_read
        AWS::S3::S3Object.store img_name_full, tmp_full, s3_bucket, :access => :public_read
        
        # Update html_body
        self.html_body.sub! img[:src], "http://#{s3_bucket}.s3.amazonaws.com/#{img_name_page}"
      end
    end
    # Done!
    self.image_processing_finished = true
  rescue
    logger.error "in process_images #{$!}"
  end
  
  
  def scrape_source_url
    # Try to extract some useful content from the remote URL
    
    return if self.source_url.blank?
    
    # Mark as finished, even if we bail out due to an error
    self.remote_url_scraped = true
    
    # Only run when there are empty fields
    return unless self.html_body.blank? or self.title.blank? or self.thumbnail_full.blank?
    
    # 
    # SPECIAL SUBMISSION TYPES
    # 
    
    # IMG
    if self.source_url.index /\.(gif|tiff|png|jpeg|jpg|bmp)$/i
      self.html_body = "<p><img src='#{self.source_url}'/></p>"
      # Skip the rest, there's nothing else we can do
      return true
    end
    
    # DO NOTHING:
    if self.source_url.index /\.(pdf|ps)$/i
      self.html_body = "" # We'll link back to this object automatically
      return true
    end
    
    # END SPECIAL TYPES
    
    
    # Get HTML source
    begin
        raw_html = open(self.source_url).read
    rescue
      logger.error "in scrape_source_url 1 #{$!}"
      return
    end
    
    # Body
    begin
      # Readabilty config
      tag_specific_attributes = {
        "img" => %w[width height]
      }
      readability_doc = Readability::Document.new raw_html, :tags=>%w[img div p strong b em i u h1 h2 h3 h4 h5 h6 ul li a br], 
                :attributes=>%w[src href], :tag_specific_attributes=>tag_specific_attributes, :score_images=>true, :sanitize_links=>true, :resolve_relative_urls_with_path=>self.source_url
      self.html_body ||= readability_doc.content
    rescue
      logger.error "in scrape_source_url 2 #{$!}"
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
    return self.thumbnail_small unless self.thumbnail_small.blank?
    nil
  end
  
  def og_url
    return self.shortened_url unless self.shortened_url.blank?
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
      logger.error "in make_thumbnail: #{$!}"
    end
    
end

# 
# t.string    :thumbnail_page
# t.string    :thumbnail_page_width
# t.string    :thumbnail_page_height
# 
# t.string    :thumbnail_small
# t.string    :thumbnail_small_width
# t.string    :thumbnail_small_height
# 
# # Constrained dimensions
# t.string    :thumbnail_thumb
# t.string    :thumbnail_square
# t.string    :thumbnail_tiny
