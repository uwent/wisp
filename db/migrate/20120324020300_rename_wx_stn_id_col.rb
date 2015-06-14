class RenameWxStnIdCol < ActiveRecord::Migration
  def self.up
    begin
      rename_column :weather_station_data, :station_id, :weather_station_id
    rescue
      "Must have already renamed the column"
    end  
  end

  def self.down
    rename_column :weather_station_data, :weather_station_id, :station_id
  end
end
