class SessionsController < ApplicationController
  
  def new
    if current_facebook_user
      flash[:notice] = ""
      redirect_to create_session_path and return
    end
  end
  
  def register
    session[:return_to] = get_started_path
    redirect_to :action => :new and return
  end
    
  
  def new_from_bookmarklet
    session[:return_to] = login_bookmarklet_success_path
    flash[:notice] = ""
    redirect_to create_session_path
  end
  
  def new_from_bookmarklet_success
  end
  
  def create
    create_connected_user
    
    if @user
      session[:user_id] = @user.id
    end
    
    if current_user
      flash[:notice] = "You're now logged in."
      redirect_to session[:return_to] || root_path
      session[:return_to] = nil
    elsif @user.nil?
      render :action=>"new"
    else
      flash[:error] = "Unable to log you in. Try again."
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
