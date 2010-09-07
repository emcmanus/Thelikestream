class SpoofController < ApplicationController
  
  before_filter :require_admin
  
  def show_form
    # List all puppets
    @puppets = User.all(:conditions=>{:is_puppet=>true})
  end
  
  def submit
    return unless current_user.is_admin
    
    # Lookup user, make sure it's a puppet
    @user = User.find(params["user_id"])
    
    flash[:notice] = "Unable to log you in as that user"
    
    if @user.is_puppet
      flash[:notice] = "Logged in as user #{@user.id}"
      session[:user_id] = @user.id
    end
    
    redirect_to root_path
  end
  
  def make_new_puppet
    begin
      puppet = User.new
      puppet.facebook_id = SecureRandom::random_number(99999) + 1
      puppet.is_god = 0
      puppet.can_admin = 1
      puppet.can_edit_raw_html = 1
      puppet.is_puppet = 1
      puppet.save
    rescue
      logger.error puppet.errors.inspect
    end
    render :content_type => "text/javascript", :layout => false
  end
end
