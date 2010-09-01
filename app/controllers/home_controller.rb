class HomeController < ApplicationController
  def show
    @links = Link.all
    
    logger.info current_user.inspect
  end
end
