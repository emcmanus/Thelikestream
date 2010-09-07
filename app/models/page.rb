# 
# create_table "pages", :force => true do |t|
#   t.string   "media_category"
#   t.string   "thumbnail_small",        :default => ""
#   t.integer  "thumbnail_small_width",  :default => 0
#   t.integer  "thumbnail_small_height", :default => 0
#   t.string   "thumbnail_full",         :default => ""
#   t.integer  "thumbnail_full_width",   :default => 0
#   t.integer  "thumbnail_full_height",  :default => 0
#   t.text     "introduction"
#   t.text     "html_body"
#   t.string   "title",                  :default => ""
#   t.string   "like_title",             :default => ""
#   t.string   "source_url"
#   t.string   "shortened_url",          :default => ""
#   t.boolean  "show_link",              :default => true
#   t.boolean  "is_cloaked",             :default => false
#   t.integer  "like_count",             :default => 0
#   t.integer  "weighted_score",         :default => 0
#   t.integer  "user_id",                                   :null => false
#   t.datetime "created_at"
#   t.datetime "updated_at"
#   t.string   "slug"
# end
# 


require 'open-uri'

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
  
  before_save :scrape_source_url
  
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
  
  def scrape_source_url
    # Try to extract some useful content from the remote URL
    
    return if self.source_url.blank?
    
    # Only run when there are empty fields
    return unless self.html_body.blank? or self.title.blank? or self.thumbnail_full.blank?
    
    # Get HTML source
    begin
      raw_html = open(self.source_url).read
    rescue
      logger.error $!
      return
    end
    
    # Body
    begin
      # Readabilty config
      tag_specific_attributes = {
        "img" => %w[width height]
      }
      readability_doc = Readability::Document.new raw_html, :tags=>%w[img div p strong b em i u h1 h2 h3 h4 h5 h6 ul li a br], 
                :attributes=>%w[src href], :tag_specific_attributes=>tag_specific_attributes, :score_images=>true, :sanitize_links=>true, :resolve_relative_urls_with_path=>self.source_url, :debug => true
      self.html_body ||= readability_doc.content
    rescue
      logger.error $!
    end
    
    # Thumbnail
    begin
      if self.thumbnail_full.blank?
        imgs = Nokogiri::HTML(self.html_body).css('img')
        imgs.each do |img|
          # Use the first image with dimensions
          continue if img.blank? or img[:width].blank? or img[:width].to_i < 1 or img[:height].blank? or img[:height].to_i < 1
          
          self.thumbnail_full = img[:src]
          self.thumbnail_full_width = img[:width].to_i
          self.thumbnail_full_height = img[:height].to_i
          
          break # Done
          
          # TODO Create small and square thumbnails
        end
      end
    rescue
      logger.error $!
    end
    
    # Title
    begin
      self.title ||= Nokogiri::HTML(raw_html).css('title').first.try :content
    rescue
      logger.error $!
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
end
