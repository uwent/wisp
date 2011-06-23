set :application, "wimnext2"
set :repository,  "svn+ssh://wayne@molly.soils.wisc.edu/var/svn/soils_ag_wx/trunk/rails-app"
set :user, "wayne"
default_run_options[:pty] = true

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/wayne/prj/#{application}"
set :deploy_via, "export"
set :use_sudo, false

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "alfi.soils.wisc.edu"
role :web, "alfi.soils.wisc.edu"
role :db,  "molly.soils.wisc.edu", :primary => true