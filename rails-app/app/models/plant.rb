class Plant < ActiveRecord::Base
  include ETCalculator # From asigbiophys gem
  
  def self.default_plant
    find_by_name 'Potato'
  end
  
  ####################
  # GROWTH CURVE CALCS
  ####################
  
  def lai_for(days_since_emergence,fdw)
    # Hack this for now with the corn method already in the gem
    lai_corn(days_since_emergence)
  end
  
  # Does this Plant use degree days in its canopy calcs?
  # If not, Field won't bother downloading them
  def uses_dds(et_method)
    false
  end
  
  ###################
  # ADJUSTED ET CALCS
  ###################
  
  def calc_adj_et_lai_for_clumping(ref_et,lai)
    adj_et_lai_for_clumping(ref_et,lai)
  end
  
  def calc_adj_et_lai_for_nonclumping(ref_et,lai)
    adj_et_lai_for_nonclumping(ref_et,lai)
  end
  
  # default implementation is nonclumping; subclasses can override
  def calc_adj_et_lai(ref_et,lai)
    adj_et_lai_for_nonclumping(ref_et,lai)
  end
  
  def calc_adj_et_pct_cover(ref_et,pct_cover)
    adj_et_pct_cover(ref_et,pct_cover)
  end
end

# Individual plant classes

class Potato < Plant; include ETCalculator; end

class SweetCorn < Plant
  include ETCalculator
  
  # This Plant has a thermally-based LAI model, so it needs degree days
  def uses_dds(et_method)
    et_method == Field::LAI_METHOD
  end
  
  def lai_for(days_since_emergence,fdw)
    puts "SweetCorn::lai_for: fdw is #{fdw.inspect}"
    lai_thermal(fdw)
  end
end
class SnapBean < Plant;  include ETCalculator; end
class ShellPeas < Plant;  include ETCalculator; end
class Onion < Plant;  include ETCalculator; end
class Cabbage < Plant;  include ETCalculator; end
class Carrot < Plant;  include ETCalculator; end
class Soybean < Plant;  include ETCalculator; end
class FieldCorn < Plant;  include ETCalculator; end
class Beets < Plant;  include ETCalculator; end
class Broccoli < Plant;  include ETCalculator; end
class Pepper < Plant;  include ETCalculator; end
class SweetPotato < Plant;  include ETCalculator; end
class Mint < Plant;  include ETCalculator; end
class Tomato < Plant;  include ETCalculator; end
class Melon < Plant;  include ETCalculator; end
class Pumpkin < Plant;  include ETCalculator; end
class WinterSquash < Plant;  include ETCalculator; end
class SummerSquash < Plant;  include ETCalculator; end
class LeafyGreens < Plant;  include ETCalculator; end
class Cucumber < Plant;  include ETCalculator; end
class Asparagus < Plant;  include ETCalculator; end
class Celery < Plant;  include ETCalculator; end
class Wheat < Plant;  include ETCalculator; end
class Alfalfa < Plant;  include ETCalculator; end
class Barley < Plant;  include ETCalculator; end
class Other < Plant;  include ETCalculator; end

