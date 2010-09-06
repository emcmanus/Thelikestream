require 'open-uri'

class Page < ActiveRecord::Base
  belongs_to :user
  
  acts_as_url :title, :url_attribute => :slug, :only_when_blank => true
  
  validates_format_of_url   :source_url
  validates_presence_of     :title
  validates_associated      :user
  
  before_save :scrape_source_url
  
  def to_param
    "#{self.id}-#{self.slug}"
  end
  
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
      readability_doc = Readability::Document.new raw_html, :tags=>%w[img div p strong b em i u h1 h2 h3 h4 h5 h6 ul li a br], 
                :attributes=>%w[src href], :score_images=>true, :sanitize_links=>true, :resolve_relative_urls_with_path=>self.source_url, :debug => true
      self.html_body ||= readability_doc.content
    rescue
      logger.error $!
    end
    
    parsed_doc = Nokogiri::HTML(raw_html)
    
    # Thumbnail
    begin
      if self.thumbnail_full.blank?
        img = parsed_doc.css('img').first
        unless img.blank? or img[:width].blank? or img[:height].blank?
          self.thumbnail_full = img[:src]
          self.thumbnail_full_width = img[:width].to_i
          self.thumbnail_full_height = img[:height].to_i
          # TODO Create small and square thumbnails
        end
      end
    rescue
      logger.error $!
    end
    
    # Title
    begin
      self.title ||= parsed_doc.css('title').first.try :content
    rescue
      logger.error $!
    end
  end
  
  
  # def secure_update(unsafe_fields, editing_user)
  #   if unsafe_fields.blank? or editing_user.nil?
  #     logger.warn "Early return from secure_update, params unsafe_fields: #{unsafe_fields.inspect}, editing_user: #{editing_user.inspect}"
  #     return false
  #   end
  #   
  #   self.title = unsafe_fields[:title]
  #   
  #   # Secure fields
  #   if editing_user.is_content_editor
  #     self.url = unsafe_fields[:url] 
  #     self.show_link = unsafe_fields[:show_link]
  #     self.preview_html = unsafe_fields[:html_body]
  #   end
  #   
  #   if editing_user.is_admin
  #     self.like_count = unsafe_fields[:like_count]
  #   end
  #   
  #   return
  # end
  
  
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
