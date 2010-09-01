class SessionsController < ApplicationController
  
  def new
    if current_facebook_user
      flash[:notice] = ""
      redirect_to create_session_path
    end
  end
  
  
  def create
    create_connected_user
    
    if @user
      session[:user_id] = @user.id
    end
    
    if current_user
      redirect_to session[:return_to] || root_path
      session[:return_to] = nil
    else
      flash[:error] = "Unable to log you in. Try logging out from Facebook, first."  # Happens when you are signed in to facebook, but not the website
      render :action=>"new"
    end
  end
  
  
  def destroy
    session[:user_id]=nil
    redirect_to root_path
  end
  
  
  def create_connected_user
    if current_facebook_user
      @user = User.find_by_facebook_id(current_facebook_user.id)
      if @user.nil?
        @user = User.create_from_validated_id current_facebook_user.id
      end
    end
  end
  
end
