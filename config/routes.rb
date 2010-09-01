ActionController::Routing::Routes.draw do |map|
  
  map.resources :users
  map.resources :links
  
  # Session
  map.logout          "/logout",          :controller => "sessions",  :action => "destroy"
  map.login           "/login",           :controller => "sessions",  :action => "new"
  map.create_session  "/session/create",  :controller => "sessions",  :action => "create"
  
  # Bookmarklet
  map.bookmarklet_js      "/bookmarklet/js",      :controller => :links,   :action => :bookmarklet_js
  map.bookmarklet_submit  "/bookmarklet/submit",  :controller => :links,   :action => :bookmarklet_submit
  
  # Global Nav
  map.home    "/home",    :controller => :home,   :action => :show
  map.profile "/profile", :controller => :users,  :action => :profile
  map.submit  "/submit",  :controller => :links,  :action => :new
  map.tools   "/tools",   :controller => :tools,  :action => :show
  
  # Root
  map.root                :controller => :home,  :action => :show
  
end
