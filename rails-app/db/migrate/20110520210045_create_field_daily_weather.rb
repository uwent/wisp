class CreateFieldDailyWeather < ActiveRecord::Migration
  def self.up
    create_table :field_daily_weather do |t|
      t.integer :field_id
      t.datetime :date
      t.float :ref_et
      t.float :adj_et
      t.float :rain
      t.float :irrigation
      t.float :entered_pct_moisture
      t.float :entered_pct_cover
      t.float :leaf_area_index
      t.float :calculated_pct_moisture
      t.float :ad
      t.float :deep_drainage
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :field_daily_weather
  end
end
