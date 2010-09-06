class PageController < ApplicationController
  
  before_filter   :require_user, :except => [:show]
  
  def show
    @page = Page.find(params[:id])  # find automatically calls to_i
  end
  
  def index
    # Redirect to home
  end
  
  def new
    # Form
  end
  
  def create
    # 
  end
  
  def update
  end
  
  def destroy
    # Soft delete
  end
  
end
