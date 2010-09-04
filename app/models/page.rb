class Page < ActiveRecord::Base
  belongs_to :user
  
  validates_format_of_url   :source_url
  validates_presence_of     :title
  validates_associated      :user
  
  def secure_update(unsafe_fields, editing_user)
    if unsafe_fields.blank? or editing_user.nil?
      logger.warn "Early return from secure_update, params unsafe_fields: #{unsafe_fields.inspect}, editing_user: #{editing_user.inspect}"
      return false
    end
    
    self.title = unsafe_fields[:title]
    
    # Secure fields
    if editing_user.is_content_editor
      self.url = unsafe_fields[:url] 
      self.show_link = unsafe_fields[:show_link]
      self.preview_html = unsafe_fields[:html_body]
    end
    
    if editing_user.is_admin
      self.like_count = unsafe_fields[:like_count]
    end
    
    return
  end
  
end
