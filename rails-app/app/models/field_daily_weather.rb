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
    # puts "fdw#results_to_field: we #{self.id} are calling #{field.inspect}"
    if field && (ref_et || rain || irrigation || entered_pct_moisture)
      field.update_fdw(self)
    end
  end
  
  def update_balances(previous_day)
    feeld = self.field
    # puts "fdw#update_balances: we (#{self.id}) have a field of #{feeld.inspect}";$stdout.flush
    if previous_day
      puts "\nprevious_day passed in, using #{previous_day.inspect}"
      previous_ad = previous_day.ad
    else
      puts "\nusing field's initial value of #{feeld.initial_ad}"
      previous_ad = feeld.initial_ad
    end
    requirements = [ "ref_et", "previous_ad", "feeld", "feeld.field_capacity", "feeld.perm_wilting_pt", "feeld.current_crop", "feeld.current_crop.max_root_zone_depth"]
    requirements.each do |cond|
      unless eval(cond)
        puts "\n#{cond} was not set -- needed to update balances"
        return
      end
    end
    adj_et = feeld.et_method.adj_et(self)
    delta_storage = calc_change_in_daily_storage(rain, irrigation, adj_et)
    total_available_water = calc_taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
    ad = calc_daily_ad(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
  end
end
