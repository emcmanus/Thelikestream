class BookmarkletController < ApplicationController
  def show
    @user_key = params[:k]
    render :content_type => "text/javascript", :layout => false
  end
  
  def page_create
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
      # Make page object
      page = Page.new
      
      # User params
      page.user = key.user
      page.title = user_title
      page.source_url = user_url
      
      unless page.valid?
        @response[:completed] = false
        @response[:message] += "Page validation error. "
        logger.warn "Page validation errors: #{page.errors.inspect}"
      end
    else
      # Invalid key, no user object
      @response[:completed] = false
      @response[:require_login] = true if current_user.nil?
    end
    
    if page and page.save
      @response[:completed] = true
      @response[:link] = url_for page
    else
      @response[:completed] = false
      @response[:message] ||= "Generic save error."
    end
    
    # Render result JSON
    render :content_type => "text/javascript", :layout => false
  end
end
