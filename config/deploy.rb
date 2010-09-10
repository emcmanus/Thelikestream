set :application, 	"likestream"
set :domain, 		"thelikestream.com"
set :port, 		2298
set :repository,  	"ssh://#{domain}:#{port}/home/git/likestream.git"
set :use_sudo,		false
set :deploy_to		"/users/emcmanus/rails_apps/#{application}"
set :scm, 		:git

role :web, domain
role :app, domain
role :db,  domain, :primary => true

after "deploy", "deploy:cleanup"

namespace :deploy do
  task :start, :roles => :app do
	run "touch #{current_release}/tmp/restart.txt
  end

  task :stop, :roles => :app do ; end
  
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end
