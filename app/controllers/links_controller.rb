require 'open-uri'

class LinksController < ApplicationController
  
  # Must be a user to post
  before_filter :require_user, :except => [:index, :show, :bookmarklet_js, :bookmarklet_submit]
  
  # GET /links
  def index
    @links = Link.all
  end


  # GET /links/1
  def show
    @link = Link.find(params[:id])
    @showIntroBanner = false
    @page_title = @link.title
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
  
  
  # There's a better place for this elsewhere
  def fill_in_link_using_url(link)
    
    return if link.url.blank?
    raw_html = open(link.url).read
    
    # Preview
    # begin
      readability_doc = Readability::Document.new raw_html, :tags=>%w[img div p strong b em i u h1 h2 h3 h4 h5 h6 ul li a br], 
                :attributes=>%w[src href], :score_images=>true, :sanitize_links=>true, :resolve_relative_urls_with_path=>link.url, :debug=>true
      logger.warn "pre-preview_html set. readability_doc: #{readability_doc}, link: #{link}"
      link.preview_html = readability_doc.content
      logger.warn "post preview set"
    # rescue
    #   logger.warn "fill_in_link_using_url, in rescue 1: #{$!}"
    # end
    
    logger.warn "finished preview_html. raw_html is still #{raw_html.length} chars"
    
    # Get title
    begin      
      if link.title.blank?
        link.title = Nokogiri::HTML(raw_html).css('title').first.try :content
      end
    rescue => err
      logger.warn "fill_in_link_using_url, in rescue 2. err: #{err}, more: #{$!}"
    end
    
    logger.warn "exiting fill_in_link_using_url"
  end
  
  
  def bookmarklet_js
    @user_key = params[:k]
    render :content_type => "text/javascript", :layout => false
  end
  
  
  def bookmarklet_submit
    user_key = params[:k]
    user_title = CGI::unescape(params[:t])
    user_url = CGI::unescape(params[:u])
    
    # JSON Response
    @response = { :completed=>false, :message=>"", :require_login=>false }
    
    # Start lookup, create the key if we have a user
    key = BookmarkletKey.find_or_initialize_by_value user_key
    
    unless key.valid?
      key.user = current_user
      unless key.save
        logger.warn "Unable to save key with info: #{key.inspect}, errors: #{key.errors.inspect}"
        @response[:completed] = false
        @response[:message] += "Key validation error. "
      end
    end
    
    if key.valid?
      link = Link.new
      link.user = key.user
      link.title = user_title
      link.url = user_url
      link.like_count = 0
      link.show_link = true
      
      fill_in_link_using_url link
      unless link.valid?
        @response[:completed] = false
        @response[:message] += "Link validation error. "
        logger.warn "Link validation errors: #{link.errors.inspect}"
      end
    else
      # Invalid key, no user object
      @response[:completed] = false
      @response[:require_login] = true if current_user.nil?
    end
    
    if link and link.save
      @response[:completed] = true
      @response[:link] = url_for link
    else
      @response[:completed] = false
      @response[:message] ||= "Generic save error."
    end
    
    # Render result JSON
    render :content_type => "text/javascript", :layout => false
  end
  

  # POST /links
  def create
    @link = Link.new(params[:link])
    
    # Secure fields
    @link.user = current_user
    @link.like_count = 0
    
    unless @link.url.blank?
      # Get preview
      fill_in_link_using_url @link
    end

    if @link.save
      redirect_to(@link, :notice => 'Link was successfully created.')
    else
      render :action => "new"
    end
  end
  

  # PUT /links/1
  def update
    link = Link.find(params[:id])
    
    # Has permission?
    redirect_to root_path and return unless current_user == link.user or current_user.is_content_editor
    
    link.secure_update(params[:link], current_user)
    
    if link.save
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
