ActionController::Routing::Routes.draw do |map|
  map.resources :jokes

  map.resources :quotes

  map.resources :videos

  map.resources :pictures

  map.resources :links
  
  # Content type
  map.vids    "vids",     :controller => :videos,   :action => :index
  map.pics    "pics",     :controller => :pictures, :action => :index
  map.quotes  "quotes",   :controller => :quotes,   :action => :index
  map.jokes   "jokes",    :controller => :jokes,    :action => :index
  
  # Global
  map.submit  "submit",   :controller => :links, :action => :new
  map.tools   "tools",    :controller => :tools, :action => :show
  
  # Root
  map.home    "home",     :controller => :home,  :action => :show
  map.root                :controller => :home,  :action => :show
  
end
