class SoilType < ActiveRecord::Base
  validates :name, uniqueness: true

  DEFAULT_SOIL_TYPE_NAME = 'Sandy Loam'

  def self.default_soil_type_attrs
    initial_types.find do |attrs|
      attrs[:name] == DEFAULT_SOIL_TYPE_NAME
    end
  end

  def self.default_soil_type
    where(default_soil_type_attrs).first
  end

  def self.seed
    initial_types.each do |attrs|
      where(attrs).first_or_create
    end
  end

  def self.initial_types
    YAML.load_file(Rails.root.join('db', 'soil_types.yml')).map do |attrs|
      attrs.with_indifferent_access
    end
  end
end
