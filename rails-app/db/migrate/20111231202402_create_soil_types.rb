class CreateSoilTypes < ActiveRecord::Migration
  def self.up
    create_table :soil_types do |t|
      t.string :name
      t.string :description
      t.float :field_capacity
      t.float :perm_wilting_pt
      t.timestamps
    end
    rename_column :fields, :soil_type, :soil_type_id
  end

  def self.down
    drop_table :soil_types
    rename_column :fields, :soil_type_id, :soil_type
  end
end
