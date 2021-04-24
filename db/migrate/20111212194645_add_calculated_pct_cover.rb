class AddCalculatedPctCover < ActiveRecord::Migration[4.2]
  def self.up
    add_column :field_daily_weather, :calculated_pct_cover, :float
  end

  def self.down
    remove_column :field_daily_weather, :calculated_pct_cover
  end
end
