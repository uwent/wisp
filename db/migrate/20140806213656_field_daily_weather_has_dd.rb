class FieldDailyWeatherHasDd < ActiveRecord::Migration[4.2]
  def self.up
    add_column :field_daily_weather, :degree_days, :integer
  end

  def self.down
    remove_column :field_daily_weather, :degree_days
  end
end
