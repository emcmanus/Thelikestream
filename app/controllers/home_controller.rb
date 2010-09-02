class HomeController < ApplicationController
  def show
    @links = Link.all
  end
end
