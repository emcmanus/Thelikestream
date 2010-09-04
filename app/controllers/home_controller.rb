class HomeController < ApplicationController
  def show
    @links = Link.all(:order=>"created_at DESC", :limit=>30)
  end
end
