class AddUniqueIndexToSoilTypesName < ActiveRecord::Migration
  def change
    add_index :soil_types, :name, unique: true
  end
end
