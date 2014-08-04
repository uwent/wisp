
# This script will go through all the current-year fields and extend their field daily
# weather records through the end of November (or whatever is defined in Field::END_DATE).

# Pull in the Rails environment. By default, you get the development enviroment; set RAILS_ENV in the shell
# environment to "production" or "test" to affect that. In Linux, that would be:
# cd root_folder_of_rails_app/db
# RAILS_ENV=production ruby add_fdw_through_november.rb

require File.join(File.dirname(__FILE__),'..','config','environment.rb')

# Do some stuff. Here, we just print the end date and the number of crop fields in the DB,
# to be sure that things are working

puts "Starting FieldDailyWeather.count "<<FieldDailyWeather.count.to_s
puts
finish_date = Date.new(2014,Field::END_DATE[0],Field::END_DATE[1])
Field.where("created_at >= '2014-01-01'").each do 
|fld| lastDate = fld.field_daily_weather[-1].date
# Need farm name in following puts
  puts fld.name
  recordsAdded = 0
  if lastDate < finish_date
    (lastDate..finish_date).each do |thedate|
            FieldDailyWeather.create!(
              :date => thedate, :ref_et => 0.0, :adj_et => 0.0, :leaf_area_index => 0.0, :calculated_pct_cover => 0.0, :field_id => fld.id
            )
    recordsAdded = recordsAdded+1 
    end
    fld.save!
  end
    puts "  lastDate: #{lastDate}, finish_date: #{finish_date}"
    puts "  Records added "<<recordsAdded.to_s
    puts
end
puts "Ending FieldDailyWeather.count "<<FieldDailyWeather.count.to_s