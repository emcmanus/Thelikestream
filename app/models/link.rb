class Link < ActiveRecord::Base
  belongs_to :user
  is_taggable :categories
  
  validates_presence_of :title
  
  validates_associated :user
  
  def secure_update(unsafe_fields, current_user)
    return false if unsafe_fields.blank? or current_user.nil?
    
    self.title = unsafe_fields[:title]
    
    # Secure fields
    if current_user.is_content_editor
      self.url = unsafe_fields[:url] 
      self.show_link = unsafe_fields[:show_link]
      self.preview_html = unsafe_fields[:preview_html]
    end
    
    if current_user.is_admin
      self.like_count = unsafe_fields[:like_count]
    end
    
    return self.save
  end
  
end
