#!/usr/bin/env ruby
# Adapted from http://www.slashdotdash.net/2007/01/09/using-activerecord-outside-rails/
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'rubygems'
# Check that we're in RAILS_ROOT
folders = Dir.glob('*')
unless folders.grep('app') && folders.grep('config')
  puts "Must run this script from RAILS_ROOT folder (i.e., there should be 'app' and 'config' subfolders, among others)"
  exit -1
end
RAILS_ROOT=`pwd`.chomp
ENV['RAILS_ENV'] = ENV['RAILS_ENV'] || 'development'
require File.join(RAILS_ROOT,'config','boot')
require File.join(RAILS_ROOT,'config','environment')

def connect(environment)
  conf = YAML::load(File.open(File.join(RAILS_ROOT,'config','database.yml')))
  ActiveRecord::Base.establish_connection(conf[environment])
end
# Open ActiveRecord connection
connect(ENV['RAILS_ENV'])

unless (email = ARGV[0])
  puts "usage: delete_for user_email\n(DELETES ALL DATA for that account!)"
  exit -1
end

# Check that user wants to go ahead
print "About to delete all data for #{email} in the #{ENV['RAILS_ENV']} environment. Continue? (ctrl-C to interrupt)"
5.times {print '.'; $stdout.flush; sleep 1 }
puts "OK!"

user = User.find_by_email(email)
raise "user not found" if user.nil?
puts "#{user.inspect}"
for group in user.groups
  for weather_station in group.weather_stations
    WeatherStation.delete weather_station[:id]
  end
  for farm in group.farms
    for pivot in farm.pivots
      for field in pivot.fields
        for fdw in field.field_daily_weather
          FieldDailyWeather.delete fdw[:id]
        end
        Field.delete field[:id]
      end
      Pivot.delete pivot[:id]
    end
    puts "destroying: #{farm.inspect}"
    Farm.delete farm[:id]
  end
  if group.users.size == 1
    Group.delete group[:id]
  end
  User.delete user[:id]
end