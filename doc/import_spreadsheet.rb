require "rubygems"
require "active_record"
require "date"
conn = ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "../rails-app/db/development.sqlite3")
class FieldDailyWeather < ActiveRecord::Base
  set_table_name :field_daily_weather
end

class IrrigationEvent < ActiveRecord::Base
end

class WeatherStationData < ActiveRecord::Base
  set_table_name :weather_station_data
end

mrzd = 36.0

def parse_the_date(date)
  fields = date.split("/")
  year = fields[2].to_i + 2000
  month = fields[0].to_i
  day = fields[1].to_i
  Date.civil(year, month, day)
end

fdws = FieldDailyWeather.find(:all, conditions: ["field_id = ?", 1]).sort_by(&:date)
max_rows = fdws.size
day = -1
linecount = 0
headers = nil
raise "can't get wx" unless fdws.size > 0
File.open(ARGV[0]) do |file|
  file.each do |line|
    linecount += 1

    fields = line.split(",")
    if (line =~ /^,Day/) && headers.nil?
      headers = fields
    end
    if !headers
      puts "no headers yet"
      puts line
      next
    end

    next unless /^,\d/.match?(line)
    puts line
    day += 1
    break if day >= max_rows
    date = parse_the_date(fields[2])
    wx = WeatherStationData.find(:first, conditions: ["date = ? and station_id = ?", date, 1])
    wx ||= WeatherStationData.create(date: date, station_id: 1)
    fdw = fdws[day]
    fdw = FieldDailyWeather.new(fdw.attributes)
    fdw.field_id = 2
    headers.each_with_index do |hdr, ii|
      next unless ii > 0
      value = if hdr == "ad"
        fields[ii].to_f / mrzd
      else
        fields[ii].to_f
      end
      if FieldDailyWeather.column_names.include?(headers[ii])
        fdw[headers[ii].to_sym] = value
      end
    end
    wx[:rainfall] = fdw[:rain]
    wx[:ref_et] = fdw[:ref_et]
    wx.save!
    irrig = fdw[:irrigation]
    if irrig && irrig > 0.0
      IrrigationEvent.create(pivot_id: 1, date: date, inches_applied: irrig)
    end
    fdw.save!
    puts fdw.inspect
  end
end
