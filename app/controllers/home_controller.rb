class HomeController < ApplicationController
  def show
    # num_pages = 30
    # 
    # @current_offset = (params[:p].to_i || 0) * num_pages
    # @next_offset = (params[:p].to_i || 0) + 1
    # 
    # @pages = Page.all(:order=>"weighted_score DESC", :limit=>num_pages, :offset=>@current_offset, :include=>[:user], :conditions=>["like_count > 0"])
    
    @pages = Page.paginate :page=>params[:page], :order => 'weighted_score DESC', :include=>[:user], :conditions=>["like_count > 0"]
  end
end
