class HomeController < ApplicationController
  def show
    @pages = Page.all(:order=>"created_at DESC", :limit=>30)
  end
end
