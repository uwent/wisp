class CropsHavePlants < ActiveRecord::Migration[4.2]
  def self.up
    add_column :crops, :plant_id, :integer
  end

  def self.down
    remove_column :crops, :plant_id
  end
end
