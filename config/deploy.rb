set :application, 	"likestream"
set :domain, 		"thelikestream.com"
set :port, 		2298
#set :repository,  	"ssh://git@#{domain}:#{port}/home/git/likestream.git"
set :repository,	"ssh://git@184.106.218.75:2298/home/git/likestream"
set :use_sudo,		false
set :user,		"emcmanus"
set :deploy_to,		"/home/emcmanus/rails_apps/#{application}"
set :deploy_via,	:copy
set :scm, 		:git

role :web, domain
role :app, domain
role :db,  domain, :primary => true

after "deploy", "deploy:cleanup"

namespace :deploy do
  task :start, :roles => :app do
	run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
	# Nothing
  end
  
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end
