class PageController < ApplicationController
  
  before_filter   :require_user, :except => [:show]
  before_filter   :require_content_editor, :only => [:index]
  
  def show
    @page = Page.find(params[:id])  # find automatically calls to_i
  end
  
  def index
    @pages = Page.all(:order=>"created_at DESC", :limit=>100)
  end
  
  def new
    @new_page = Page.new
  end
  
  def create
    # 
  end
  
  def edit
    @page = Page.find(params[:id])
  end
  
  def update
    @page = Page.find(params[:id])
    
    # Default perms
    accept_fields = []
    update_values = {}
    
    if current_user.is_god
      accept_fields = Page::EDIT_PERMISSIONS[:god]
    elsif current_user.is_admin
      accept_fields = Page::EDIT_PERMISSIONS[:admin]
    elsif current_user.is_content_editor
      accept_fields = Page::EDIT_PERMISSIONS[:editor]
    elsif current_user
      accept_fields = Page::EDIT_PERMISSIONS[:owner]
    end
    
    params["page"].each do |key, value|
      update_values[key] = value if accept_fields.include? key
    end
    
    @page.update_attributes!(update_values)
    flash[:notice] = "Updates saved!"
    redirect_to @page and return
  rescue ActiveRecord::RecordInvalid => e
    @page = e.record
    flash[:error] = @page.errors.full_messages.to_sentance
    render :action => "edit"
  end
  
  def destroy
    # TODO Soft delete
    @page = Page.find(params[:id])
    if current_user.is_content_editor or current_user == @page.user
      @page.destroy
      flash[:notice] = "Page removed."
    end
    redirect_to page_index_path
  end
  
end
