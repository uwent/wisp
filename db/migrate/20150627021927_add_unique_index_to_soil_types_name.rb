class AddUniqueIndexToSoilTypesName < ActiveRecord::Migration[4.2]
  def change
    add_index :soil_types, :name, unique: true
  end
end
