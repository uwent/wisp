#!/usr/bin/env ruby
# per http://www.slashdotdash.net/2007/01/09/using-activerecord-outside-rails/
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'rubygems'
ENV['RAILS_ENV'] = ENV['RAILS_ENV'] || 'development'
require File.dirname(__FILE__) + '/../../config/boot'
RAILS_ROOT=`pwd`.chomp
require "#{RAILS_ROOT}/config/environment"
def connect(environment)
  conf = YAML::load(File.open(File.join(File.dirname(__FILE__), '..','config','database.yml')))
  ActiveRecord::Base.establish_connection(conf[environment])
end
# Open ActiveRecord connection
connect(ENV['RAILS_ENV'])

email = ARGV[0] || 'fewayne@gmail.com'

user = User.find_by_email(email)
raise "user not found" unless user
puts "#{user.inspect}"
for group in user.groups
  puts "  #{group.inspect}"
  for weather_station in group.weather_stations
    puts "    #{weather_station.inspect}"
  end
  for farm in group.farms
    puts "    #{farm.inspect}"
    for pivot in farm.pivots
      puts "      #{pivot.inspect}"
      for field in pivot.fields
        puts "        #{field.inspect}"
        puts "        #{field.field_daily_weather.first.date} to #{field.field_daily_weather.last.date}"
      end
    end
  end
end