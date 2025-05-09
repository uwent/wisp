branch = ENV["BRANCH"] || "main"

set :application, "wisp"
set :repo_url, "git@wisp.github.com:uwent/wisp.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, branch

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/deploy/wisp"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets]

# Default value for default_env is {}
# set :default_env, { path: '/opt/ruby/bin:$PATH' }

# Default value for keep_releases is 5
# set :keep_releases, 5

# rbenv
set :deploy_user, "deploy"
set :rbenv_type, :user
set :rbenv_ruby, "3.4.2"

namespace :deploy do
  desc "Restart application"
  after :publishing, :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end
end
