class WxStnDataToPctMoistRename < ActiveRecord::Migration[4.2]
  # rename this column so it's consistent with the usage in FieldDailyWeather
  def self.up
    begin
      rename_column :weather_station_data, :soil_moisture, :entered_pct_moisture
    rescue Exception => e
      puts "must have already renamed it"
    end

  end

  def self.down
    rename_column :weather_station_data, :entered_pct_moisture, :soil_moisture
  end
end
