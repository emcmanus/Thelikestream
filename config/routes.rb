ActionController::Routing::Routes.draw do |map|
  
  map.resources :users
  map.resources :page
  
  # Session
  map.create_session  "/session/create",  :controller => :sessions,  :action => :create
  map.logout          "/logout",          :controller => :sessions,  :action => :destroy
  map.login           "/login",           :controller => :sessions,  :action => :new
  map.login_bookmarklet           "/login/bookmarklet",       :controller => :sessions, :action => :new_from_bookmarklet
  map.login_bookmarklet_success   "/login/bookmarklet/done",  :controller => :sessions, :action => :new_from_bookmarklet_success
  
  # Bookmarklet
  map.bookmarklet_js      "/bookmarklet/show",    :controller => :bookmarklet,   :action => :show
  map.bookmarklet_submit  "/bookmarklet/submit",  :controller => :bookmarklet,   :action => :page_create
  
  # Global Nav
  map.home    "/home",    :controller => :home,   :action => :show
  map.profile "/profile", :controller => :users,  :action => :profile
  map.submit  "/submit",  :controller => :page,   :action => :new
  map.tools   "/tools",   :controller => :tools,  :action => :show
  
  # Voting
  map.vote_cast "/vote_cast",   :controller => :vote,   :action => :vote_for_url
  
  # Admin
  map.spoof   "/admin/spoof",    :controller => :spoof,   :action => :show_form
  map.spoof_submit  "/admin/spoof/submit", :controller => :spoof, :action => :submit
  map.spoof_create  "/admin/spoof/create", :controller => :spoof, :action => :make_new_puppet
  
  # Root
  map.root      :controller => :home,  :action => :show
  
  # Page via slug
  map.page      "/:id",           :controller => :page, :action => :show
end
