class CreateMultiEditLinks < ActiveRecord::Migration
  def self.up
    create_table :multi_edit_links do |t|
      t.integer :field_id
      t.integer :weather_station_id

      t.timestamps
    end
  end

  def self.down
    drop_table :multi_edit_links
  end
end
