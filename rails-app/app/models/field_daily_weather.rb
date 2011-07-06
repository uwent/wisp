require 'ad_calculator'
class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  before_save :results_to_field
  
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
  
  # def leaf_area_index
  #   if leaf_area_index then return leaf_area_index; else raise 'leaf_area_index not yet implemented'; end
  # end
  
  def crop_coeff
    # Here's an example of how to call one of the module methods
    # calc_TAW(1.0,1.0,1.0)
  end
  
  # We've changed, so notify our field so it can recalculate
  def results_to_field
    if field && (ref_et || rain || irrigation || entered_pct_moisture)
      field.update_fdw(self)
    end
  end
  
  def update_balances(previous_day)
    if previous_day
      previous_ad = previous_day.ad
    else
      puts "using field's initial value of #{field.inital_ad}"
      previous_ad = field.initial_ad
    end
    if ref_et && previous_ad && field && field.field_capacity && field.perm_wilting_pt && field.current_crop && field.current_crop.max_root_zone_depth
      adj_et = field.et_method.adj_et(self)
      delta_storage = calc_change_in_daily_storage(rain, irrigation, adj_et)
      total_available_water = calc_taw(field.field_capacity, field.perm_wilting_pt, field.current_crop.max_root_zone_depth)
      ad = calc_daily_ad(previous_ad, delta_storage, field.current_crop.max_allowable_depletion_frac, total_available_water)
    else
      puts "No field"; return unless field
      puts "No crop"; return unless field.current_crop
      puts "Missing value, could not calculate."
      puts "ref_et: #{ref_et}  previous_ad: #{previous_ad}  field.field_capacity: #{field.field_capacity}"
      puts "field.perm_wilting_pt: #{field.perm_wilting_pt}"
      puts "field.current_crop.max_root_zone_depth: #{field.current_crop.max_root_zone_depth} "
    end
  end
end
