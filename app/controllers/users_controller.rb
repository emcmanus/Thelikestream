class UsersController < ApplicationController
  
  # 
  # There is no new user form, the user is created after a successful connect in sessions_controller
  # 
  
  before_filter :require_user, :except => [:show]
  before_filter :require_admin, :only => [:index, :new, :create, :edit, :update]
  
  def profile
    @user = current_user
    render :action => "show"
  end
  
  def show
    if params[:id].blank?
      redirect_to profile_path and return
    else
      @user = User.find(params[:id])
    end
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
    unless current_user.is_god
      params[:user][:is_god] = 0
    end
    @user = User.create!(params[:user])
    redirect_to @user
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    flash[:error] = @user.errors.full_messages.to_sentence
    render :action=>"new"
  end
  
  
  def edit
    @user = User.find(params[:id])
  end
  
  
  def update
    @user = User.find(params[:id])
    @user.update_attributes!(params[:user])
    redirect_to @user
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    flash[:error] = @user.errors.full_messages.to_sentence
    render :action=>"show"    
  end
  
  
  
end
