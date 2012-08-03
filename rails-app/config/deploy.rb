set :application, "wisp"
set :repository,  "https://wayne@molly.soils.wisc.edu/svn_repos/IrrigSched/trunk/rails-app"
set :user, "root"
default_run_options[:pty] = true

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/"
set :deploy_via, "export"
set :use_sudo, false

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :current_dir, 'railsapp'
role :app, "wisp.cals.wisc.edu"
role :web, "wisp.cals.wisc.edu"
role :db,  "wisp.cals.wisc.edu", :primary => true

task :after_update_code, :roles => :app do
  # Since we want a different setup even for development -- the grids have us stuck in dev right now...
  run "cp #{release_path}/config/database.deployed.yml #{release_path}/config/database.yml"
  # Blip what Cap currently understands to be the repo rev number to the "build" partial
  run "echo #{revision}" > "#{current_path}/app/views/wisp/partials/_build.html.erb"
end

namespace :deploy do
  desc 'Restart the Passenger app'
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end
