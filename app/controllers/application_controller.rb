# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  
  helper_method :current_user_session, :current_user
  
  # Log filtering
  filter_parameter_logging :password, :password_confirmation
  
  
  private
    
    def current_user_session
      #
    end

    def current_user
      1
    end
  
end
