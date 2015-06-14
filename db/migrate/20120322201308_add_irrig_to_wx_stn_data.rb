class AddIrrigToWxStnData < ActiveRecord::Migration
  def self.up
    add_column :weather_station_data, :irrigation, :float
  end

  def self.down
    remove_column :weather_station_data, :irrigation
  end
end
