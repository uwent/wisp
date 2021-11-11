class WxStnDataToRain < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :weather_station_data, :rainfall, :rain
  rescue Exception => e
    puts "must have already renamed it"
  end

  def self.down
    rename_column :weather_station_data, :rain, :rainfall
  end
end
