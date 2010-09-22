# Methods added to this helper will be available to all templates in the application.

require 'uri/http'

module ApplicationHelper
  def host_with_port
    value = "#{request.host}"
    value += ":#{request.port}" if request.port != 80
    value
  end
  
  def image_url(source) 
     abs_path = image_path(source) 
     unless abs_path =~ /^http/ 
       abs_path = "http://#{host_with_port}#{abs_path}" 
     end 
     abs_path 
  end
  
  def get_unpublished_pages
    return nil unless current_user
    return @unpublished_pages if @unpublished_pages
    @unpublished_pages = Page.all :conditions=>["user_id = ? AND like_count = 0", current_user.id]
  end
  
  def get_host(full_url)
    u = URI.parse(full_url)
    u.host
  rescue
    ""
  end
  
end
