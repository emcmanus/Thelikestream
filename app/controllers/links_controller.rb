class LinksController < ApplicationController
  
  # Must be a user to post
  before_filter :require_user, :except => ['index', 'show']
  
  # GET /links
  def index
    @links = Link.all
  end


  # GET /links/1
  def show
    @link = Link.find(params[:id])
  end
  
  def bookmarklet
    @link = Link.new
    @link.title = params[:t]
    @link.url = params[:u]
    render :action => :new, :layout => 'plainApplication'
  end

  # GET /links/new
  def new
    @link = Link.new
    @link.title = params[:t]
    @link.url = params[:u]
  end
  

  # GET /links/1/edit
  def edit
    @link = Link.find(params[:id])
  end


  # POST /links
  def create
    @link = Link.new(params[:link])
    
    # Secure fields
    @link.user = current_user
    @link.like_count = 0
    
    # TODO: Get Preview HTML

    if @link.save
      redirect_to(@link, :notice => 'Link was successfully created.')
    else
      render :action => "new"
    end
  end
  

  # PUT /links/1
  def update
    @link = Link.find(params[:id])
    
    # Has permission?
    redirect_to root_path and return unless current_user == @link.user or current_user.is_content_editor
    
    if @link.secure_update(params[:link], current_user)
      redirect_to(@link, :notice => 'Link was successfully updated.')
    else
      render :action => "edit"
    end
  end
  

  # DELETE /links/1
  # DELETE /links/1.xml
  def destroy
    @link = Link.find(params[:id])
    @link.destroy

    respond_to do |format|
      format.html { redirect_to(links_url) }
      format.xml  { head :ok }
    end
  end
end
