require 'ad_calculator'
class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  
  include ADCalculator
  
  def pct_moisture
    entered_pct_moisture || calculated_pct_moisture
  end
  
  def pct_moisture=(moisture)
    entered_pct_moisture = moisture
  end
  
  def pct_cover
    if entered_pct_cover then return entered_pct_cover; else raise 'pct_cover not yet implemented'; end
  end
  
  def leaf_area_index
    if entered_leaf_area_index then return entered_leaf_area_index; else raise 'leaf_area_index not yet implemented'; end
  end
  
  def crop_coeff
    # Here's an example of how to call one of the module methods
    # calc_TAW(1.0,1.0,1.0)
  end
end
