class AddIrrigToWxStnData < ActiveRecord::Migration[4.2]
  def self.up
    add_column :weather_station_data, :irrigation, :float
  end

  def self.down
    remove_column :weather_station_data, :irrigation
  end
end
