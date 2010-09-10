# Methods added to this helper will be available to all templates in the application.
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
end
