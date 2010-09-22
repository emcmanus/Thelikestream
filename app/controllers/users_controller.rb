class UsersController < ApplicationController
  
  # 
  # There is no new user form, the user is created after a successful connect in sessions_controller
  # 
  
  before_filter :require_user, :except => [:show]
  before_filter :require_admin, :except => [:show, :profile, :edit, :update]
  
  def profile
    @user = current_user
    @nav_page = 'profile'
    render :action => "show"
  end
  
  def show
    if params[:id].blank?
      redirect_to profile_path and return
    else
      @user = User.find(params[:id])
    end
    @nav_page = 'profile'
    if @user.blank?
      flash[:notice] = "Could not find user."
      redirect_to root_path
    end
  end
  
  
  # 
  # Admin Actions
  # 
  
  def index
    @users = User.all
  end
  
  
  def new
    @user = User.new
  end
  
  
  def create
    @user = User.new params[:user]
    if @user.save
      redirect_to user_path(@user) and return
    else
      logger.warn @user.errors.inspect
      redirect_to new_user_path and return
    end
  end
  
  
  def edit
    @user = User.find(params[:id])
    
    # You can only edit yourself, unless you're an admin
    redirect_to root_url and return unless @user == current_user or current_user.is_admin
  end
  
  
  def update
    @user = User.find(params[:id])
    
    # You can only edit yourself, unless you're an admin
    redirect_to root_url and return unless @user == current_user or current_user.is_admin

    # Default perms
    accept_fields = []
    update_values = {}

    if current_user.is_god
      accept_fields = User::EDIT_PERMISSIONS[:god]
    elsif current_user.is_admin
      accept_fields = User::EDIT_PERMISSIONS[:admin]
    elsif current_user.is_content_editor
      accept_fields = User::EDIT_PERMISSIONS[:editor]
    elsif current_user == @user
      accept_fields = User::EDIT_PERMISSIONS[:owner]
    end

    params["user"].each do |key, value|
      update_values[key] = value if accept_fields.include? key
    end
    
    # Update
    @user.update_attributes!(update_values)
    flash[:notice] = "Updates saved!"
    redirect_to @user and return
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    flash[:error] = @user.errors.full_messages.to_sentance
    render :action => "show"
  end
  
  def destroy
    begin
      @user = User.find(params[:id])
    
      # You can only edit yourself, unless you're an admin
      redirect_to root_url and return unless @user == current_user or current_user.is_admin
      
      if @user.is_puppet or current_user.is_god
        @user.destroy
        flash[:notice] = "User destroyed"
      else
        flash[:notice] = "Only God can deleting normal users"
      end
    rescue
      flash[:notice] = "User does not exist" if current_user.is_admin
    end
    redirect_to users_path
  end
  
end
