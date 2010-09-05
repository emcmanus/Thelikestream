class Page < ActiveRecord::Base
  belongs_to :user
  
  validates_format_of_url   :source_url
  validates_presence_of     :title
  validates_associated      :user
  
  before_save :scrape_source_url
  
  def scrape_source_url
    return if self.source_url.blank?
    
    raw_html = open(self.source_url).read
    
    # Body and introduction
    begin
      readability_doc = Readability::Document.new raw_html, :tags=>%w[img div p strong b em i u h1 h2 h3 h4 h5 h6 ul li a br], 
                :attributes=>%w[src href], :score_images=>true, :sanitize_links=>true, :resolve_relative_urls_with_path=>self.source_url
      self.html_body = readability_doc.content
      self.introduction = ActionView::Helpers::TextHelper::truncate(Nokogiri::HTML(self.html_body).text, :length=>140, :separator=>" ")
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
