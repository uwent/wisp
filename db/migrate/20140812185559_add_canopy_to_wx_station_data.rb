class AddCanopyToWxStationData < ActiveRecord::Migration
  def self.up
    add_column :weather_station_data, :entered_pct_cover, :float
    add_column :weather_station_data, :leaf_area_index, :float
  end

  def self.down
    remove_column :weather_station_data, :entered_pct_cover
    remove_column :weather_station_data, :leaf_area_index
  end
end
