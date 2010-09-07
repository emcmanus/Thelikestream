class HomeController < ApplicationController
  def show
    @pages = Page.all(:order=>"weighted_score DESC", :limit=>30)
  end
end
