class RenameWxStnIdCol < ActiveRecord::Migration
  def self.up
    if column_exists?(:weather_station_data, :station_id)
      rename_column :weather_station_data, :station_id, :weather_station_id
    end
  end

  def self.down
    rename_column :weather_station_data, :weather_station_id, :station_id
  end
end
