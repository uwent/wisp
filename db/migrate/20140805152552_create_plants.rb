class CreatePlants < ActiveRecord::Migration[4.2]
  def self.up
    create_table :plants do |t|
      t.string :name
      t.string :type
      t.float :default_max_root_zone_depth

      t.timestamps
    end

    # Populate lookup table for Plants here. Read "plants.yml" with Ruby's YAML class and iterate through with the create method, something like
    hash = YAML::load_file(File.open(File.join('db','plants.yml'))).each do |key,details|
       Plant.create(details)
    end
    # In ActiveRecord::Base#create with STI, the class (above, Plant) trumps anything you set in the "type"
    # field manually, so we have to go through it again, set the type field, and save. Next time we pull from DB, correct class will be instantiated.
    hash.each do |key,details|
      rec = Plant.find_by_name details['name']
      rec.type = details['type']
      rec.save!
    end
    
  end

  def self.down
    drop_table :plants
  end
end
