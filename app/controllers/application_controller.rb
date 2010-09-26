# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'active_support/secure_random'

class ApplicationController < ActionController::Base
  
  include Facebooker2::Rails::Controller
  
  # Log filtering
  filter_parameter_logging :password, :password_confirmation, :fb_sig_friends
  protect_from_forgery
  
  helper :all
  helper_method :current_user, :top_pages
  
  private
    def current_user
      if session[:user_id]
        @current_user ||= User.find(session[:user_id])
      elsif current_facebook_user and @current_user.nil?
        @current_user = User.find_by_facebook_id(current_facebook_user.id)
      end
      @current_user
    end
    
    def top_pages
      #TODO fix this to use the count of objects that meet this criteria
      Page.all(:order=>"weighted_score DESC", :limit=>10, :offset=>rand(Page.count-20), :conditions=>["like_count > 0 and thumbnail_full is not NULL and show_in_favorites=true"])
    end
    
    
    # User Permission
    
    def require_god
      require_user
      redirect_to root_path unless current_user and current_user.is_god
    end
    
    def require_admin
      require_user
      redirect_to root_path unless current_user and current_user.is_admin
    end
    
    def require_content_editor
      require_user
      redirect_to root_path unless current_user and current_user.is_content_editor
    end
    
    def require_user
      unless current_user
        flash[:notice] = "Please log in first"
        session[:return_to] = request.request_uri
        redirect_to login_path
        return false
      end
    end
    
end
