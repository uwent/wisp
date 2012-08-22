require 'rubygems'
require 'yaml'
require 'active_record'

rails_path = File.join(File.dirname(__FILE__),'..')
puts rails_path
@environment = ENV['RACK_ENV'] || 'development'
yaml_path = File.join(rails_path,'config/database.yml')
puts yaml_path
@dbconfig = YAML.load(File.read(yaml_path))
ActiveRecord::Base.establish_connection @dbconfig[@environment]

#Load All models 
Dir.glob(File.join(rails_path,"app/models/{user,group,farm,pivot,field,crop,field_daily_weather,et_method,weather_station,membership}")).each do |file|
  require file 
end

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