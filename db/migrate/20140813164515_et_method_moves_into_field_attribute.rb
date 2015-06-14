class EtMethodMovesIntoFieldAttribute < ActiveRecord::Migration
  def self.up    
    # Propagate existing farms' ET methods to all of their fields
    # TODO: After this migration is accomplished, fix cloning code to
    # also clone the Plants!
    add_column :fields, :et_method, :integer
    method = Field::PCT_COVER_METHOD
    Farm.all do |farm|
      if farm.et_method.method_name == "LAI"
        method = Field::LAI_METHOD
      end
      farm.fields.each do |field|
        field.et_method = method
        field.plant = Plant.default_plant
        field.save!
      end
    end
    
    remove_column :farms, :et_method_id
    drop_table :et_methods
  end

  def self.down
    # This is pretty much irreversible; once the change to the models has been
    # committed, there are no EtMethod models to instantiate.
    puts "Can't reverse this migration"
  end
end
