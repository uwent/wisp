# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Learn more: http://github.com/javan/whenever

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# the gem paths
set :env_path, '"$HOME/.rbenv/shims":"$HOME/.rbenv/bin"'

job_type :rake,   %q{ cd :path && PATH=:env_path:"$PATH" RAILS_ENV=:environment bundle exec rake :task --silent :output }
job_type :runner, %q{ cd :path && PATH=:env_path:"$PATH" script/rails runner -e :environment ':task' :output }
job_type :script, %q{ cd :path && PATH=:env_path:"$PATH" RAILS_ENV=:environment bundle exec script/:task :output }

# Deletes all data on Feb 15 of each year
every "0 1 15 2 *" do
  rake "yearly:reset"
end
