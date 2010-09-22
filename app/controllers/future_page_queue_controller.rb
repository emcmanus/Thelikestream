# t.string   "media_category"
# t.string   "thumbnail_small",        :default => ""
# t.integer  "thumbnail_small_width",  :default => 0
# t.integer  "thumbnail_small_height", :default => 0
# t.string   "thumbnail_full",         :default => ""
# t.integer  "thumbnail_full_width",   :default => 0
# t.integer  "thumbnail_full_height",  :default => 0
# t.text     "introduction"
# t.text     "html_body"
# t.string   "title",                  :default => ""
# t.string   "like_title",             :default => ""
# t.string   "source_url"
# t.string   "shortened_url",          :default => ""
# t.boolean  "show_link",              :default => true
# t.boolean  "is_cloaked",             :default => false
# t.integer  "like_count",             :default => 0
# t.integer  "weighted_score",         :default => 0
# t.string   "slug"
# t.integer  "user_id",                                   :null => false
# t.datetime "launch_threshold"
# t.datetime "created_at"
# t.datetime "updated_at"

class FuturePageQueueController < ApplicationController
  
  before_filter :require_admin
  
  def index
    @pages = FuturePage.all
    logger.warn @pages.inspect
  end
  
  def new
    @new_page = FuturePage.new
  end
  
  def prefill
    # Create a new page, prefill content but DON'T SAVE
    # Move fields over to FuturePage object
    # Set launch_threshold
    # Save
    
    # Yep, and this is broken before anyone uses it.
    render :text => "took queueing offline for a bit"
    
    # unless params[:future_page][:source_url].blank?
    #   @tmp_page = Page.new
    #   @tmp_page.source_url = params[:future_page][:source_url]
    #   @tmp_page.user = current_user
    #   @tmp_page.scrape_source_url
    # 
    #   @page = FuturePage.new params[:future_page]
    #   @page.update_attributes @tmp_page.attributes
    #   
    #   redirect_to edit_future_page_queue_path(@page) and return
    # end
    # 
    # flash[:notice] = "Unable to save page."
    # redirect_to future_page_queue_path
  end
  
  def edit
    @future_page = FuturePage.find params[:id]
  end
  
  def update
    @future_page = FuturePage.find params[:id]
    if @future_page.update_attributes params[:future_page]
      flash[:notice] = "Record updated."
    else
      flash[:notice] = "Unable to save page."
    end
    redirect_to future_page_queue_path
  end
  
  def destroy
    @future_page = FuturePage.find params[:id]
    @future_page.destroy
    flash[:notice] = "Destroyed"
    redirect_to future_page_queue_path
  end
end
