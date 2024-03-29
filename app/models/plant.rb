class Plant < ApplicationRecord
  include ETCalculator

  def self.default_plant
    where(name: "Potato").first
  end

  def self.initial_types
    YAML.load_file(Rails.root.join("db", "plants.yml")).values.map do |attrs|
      attrs.with_indifferent_access
    end
  end

  def self.seed
    initial_types.each do |attrs|
      klass = attrs[:type].constantize
      klass.where(attrs).first_or_create
    end
  end

  ####################
  # GROWTH CURVE CALCS
  ####################

  # TODO: What does 'fdw' stand for?
  # TODO: If we don't use it, why make it a required positional argument?
  def lai_for(days_since_emergence, fdw)
    # Hack this for now with the corn method already in the gem
    lai_corn(days_since_emergence)
  end

  def uses_degree_days?(et_method)
    false
  end

  ###################
  # ADJUSTED ET CALCS
  ###################

  # TODO: Rename variables to spell out the acronyms.
  def calc_adj_et_lai_for_clumping(ref_et, lai)
    adj_et_lai_for_clumping(ref_et, lai)
  end

  def calc_adj_et_lai_for_nonclumping(ref_et, lai)
    adj_et_lai_for_nonclumping(ref_et, lai)
  end

  # default implementation is nonclumping; subclasses can override
  def calc_adj_et_lai(ref_et, lai)
    adj_et_lai_for_nonclumping(ref_et, lai)
  end

  def calc_adj_et_pct_cover(ref_et, pct_cover)
    adj_et_pct_cover(ref_et, pct_cover)
  end
end
