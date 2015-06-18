class AddPivotsToWxStns < ActiveRecord::Migration
  def self.up
    add_column :weather_stations, :pivot_id, :integer
  end

  def self.down
    remove_column :weather_stations, :pivot_id
  end
end
