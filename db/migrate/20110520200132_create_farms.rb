class CreateFarms < ActiveRecord::Migration[4.2]
  def self.up
    create_table :farms do |t|
      t.integer :group_id
      t.integer :year # for future use
      t.string :name
      t.integer :et_method_id
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :farms
  end
end
