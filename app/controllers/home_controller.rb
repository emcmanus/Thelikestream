class HomeController < ApplicationController
  # Popular Stories
  def show
    @pages = Page.paginate :page=>params[:page], :order => 'weighted_score DESC', :include=>[:user], :conditions=>["weighted_score > 0 and show_in_popular=true"]
    @nav_page = "popular"
  end

  # Recent Stories
  def recent
    @new_pages = Page.paginate :page=>params[:page], :order=> 'created_at DESC', :include=>[:user], :conditions=>["weighted_score > 0"]
    @nav_page = "recent"
  end
end
