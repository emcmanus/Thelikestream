class PageController < ApplicationController
  
  before_filter   :require_user, :except => [:show, :title_partial, :body_partial]
  before_filter   :require_content_editor, :only => [:index]
  
  def title_partial
    # Ajax request to navigate to new page
    @page = Page.find params[:id]
    render :partial => "pageTitle"
  end
  
  def body_partial
    # Ajax request to navigate to new page
    @page = Page.find params[:id]
    render :partial => "pageBody"
  end
  
  def show
    if params[:id].downcase == "home"
      redirect_to root_path and return
    end
    
    @page = Page.find(params[:id])  # find automatically calls to_i
    # For ajax story loading
    @lower_five = Page.find :all, :select=>:id, :order=>"weighted_score DESC", :conditions=>["like_count > 0 AND weighted_score < ?", @page.weighted_score], :limit=>5
    @higher_five = Page.find :all, :select=>:id, :order=>"weighted_score", :conditions=>["like_count > 0 AND weighted_score > ?", @page.weighted_score], :limit=>5
    @html_title = @page.title
  end
  
  def index
    @pages = Page.all(:order=>"created_at DESC", :limit=>100)
  end
  
  def new
    @new_page = Page.new
    @nav_page = "submit"
  end
  
  def create
    # Given only the URL
    @page = Page.new({"source_url"=>params[:page]["source_url"].sub(" ", ""), "title"=>params[:page]["title"]})
    @page.user = current_user
    @page.scrape_source_url
    @page.ready_to_process_images = true
    @page.save
    redirect_to edit_page_path(@page) and return
  end
  
  def edit
    @page = Page.find(params[:id])
    
    if @page.created_with_builder
      redirect_to page_builder_edit_path(@page) and return unless params[:edit_html]
    end
    
    unless current_user.is_content_editor or current_user == @page.user
      flash[:notice] = "You can't edit that page."
      redirect_to @page and return
    end
  end
  
  def update
    @page = Page.find(params[:id])
    
    unless current_user.is_content_editor or current_user == @page.user
      flash[:notice] = "You can't edit that page."
      redirect_to @page and return
    end
    
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
    flash[:error] = @page.errors.full_messages.to_sentence
    render :action => "edit"
  end
  
  def destroy
    # TODO Soft delete
    @page = Page.find(params[:id])
    if current_user.is_content_editor or current_user == @page.user
      @page.destroy
      flash[:notice] = "Page removed."
    end
    redirect_to root_path
  end
  
end
