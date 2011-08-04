require 'ad_calculator'
class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  before_create :zero_rain_and_irrig
  before_update :update_balances
  after_update :update_next_days_balances
  
  include ADCalculator
  # from the ActsAsAdjacent plugin, which (with this) we don't need
  scope :previous, lambda { |i| {:limit => 1, :conditions => ["#{self.table_name}.id < ? and #{self.table_name}.field_id = ?", i.id,i.field_id], :order => "#{self.table_name}.id DESC"} }
  scope :next, lambda { |i| {:limit => 1, :conditions => ["#{self.table_name}.id > ? and #{self.table_name}.field_id = ?", i.id,i.field_id], :order => "#{self.table_name}.id ASC"}}
  
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
    
  def update_balances(previous_day=nil)
    
    previous_day ||= self.pred
    feeld = self.field
    # puts "fdw#update_balances: we (#{self.id}) have a field of #{feeld.inspect}";$stdout.flush
    if previous_day
      # puts "\nprevious_day passed in, using #{previous_day.inspect}"
      previous_ad = previous_day.ad
    else
      # puts "\nusing field's initial value of #{feeld.initial_ad}"
      previous_ad = feeld.initial_ad
    end
    requirements = [ "ref_et", "previous_ad", "feeld", "feeld.field_capacity", "feeld.perm_wilting_pt", "feeld.current_crop", "feeld.current_crop.max_root_zone_depth"]
    requirements.each do |cond|
      unless eval(cond)
        puts("\n#{self[:id]}: #{cond} was not set -- needed to update balances.\n  #{self.inspect}\n  #{self.field.inspect}\n  #{self.field.current_crop.inspect}") if self[:id]
        return
      end
    end
    adj_et = feeld.et_method.adj_et(self)
    delta_storage = calc_change_in_daily_storage(rain, irrigation, adj_et)
    unless delta_storage == 0
      total_available_water = calc_taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
      ad = calc_daily_ad(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
    end
  end
  
  def update_next_days_balances
    next_day = self.succ
    if self[:ad]
      next_day.save! # triggers the update_balances method
    end
  end
  
  def zero_rain_and_irrig
    self.rain ||= 0.0
    self.irrigation ||= 0.0
  end
  
  # Instance method using the scope above
  def pred
    FieldDailyWeather.previous(self).first
  end
  
  def succ
    FieldDailyWeather.next(self).first
  end
end
