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
    @page = Page.new
    @nav_page = "submit"
  end

  def create
    # quick method-specific validation
    if ( params[:page]["source_url"].blank? )
      @page = Page.new
      @page.errors.add_to_base("You must submit a URL!")
      render :action=>:new and return
    else
      # Given only the URL
      @page = Page.new({"source_url"=>params[:page]["source_url"].sub(" ", ""), "title"=>params[:page]["title"]})
      @page.user = current_user
      @page.created_with_site_form = true
      @page.scrape_source_url
      @page.ready_to_process_images = true
      logger.warn "PAGE: " + @page.inspect
      if @page.save
        #redirect_to assign_category_path(@page) and return
        redirect_to edit_page_path(@page) and return
      else
        render :action=>:new
      end
    end
  end

  def edit_cateogory
    # Render form
  end

  def submit_category
    # Category labels:
    @page = Page.find params[:id]

    unless current_user.is_content_editor or current_user == @page.user
      redirect_to root_path and return
    end

    if params[:category].blank?
      redirect_to root_path and return
    end

    case params[:category].downcase
    when "breaking_tech"
      @page.show_in_category_breaking_tech = true
    when "games"
      @page.show_in_category_games = true
    when "gossip"
      @page.show_in_category_gossip = true
    when "music"
      @page.show_in_category_musc = true
    when "funny"
      @page.show_in_category_funny= true
    when "smart"
      @page.show_in_categiry_smart = true
    when "community"
      @page.show_in_category_community = true
    when "other"
      @page.show_in_category_other = true
    end

    if @page.save
      redirect_to edit_page_path(@page)
    end 
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
