class HomeController < ApplicationController
  def show
    @pages = Page.all(:order=>"weighted_score DESC", :limit=>30, :include=>[:user], :conditions=>["like_count > 0"])
  end
end
