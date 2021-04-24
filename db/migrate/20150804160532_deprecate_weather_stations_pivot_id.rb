class DeprecateWeatherStationsPivotId < ActiveRecord::Migration[4.2]
  def change
    rename_column :weather_stations, :pivot_id, :pivot_id_deleted
  end
end
