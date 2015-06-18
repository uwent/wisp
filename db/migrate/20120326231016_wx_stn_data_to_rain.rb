class WxStnDataToRain < ActiveRecord::Migration
  def self.up
    begin
      rename_column :weather_station_data, :rainfall, :rain
    rescue Exception => e
      puts "must have already renamed it"
    end
  end

  def self.down
    rename_column :weather_station_data, :rain, :rainfall
  end
end
