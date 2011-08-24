require 'ad_calculator'
class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  before_create :zero_rain_and_irrig
  before_update :update_balances
  after_update :update_next_days_balances
  
  include ADCalculator
  # from the ActsAsAdjacent plugin, which (with this) we don't need
  scope :previous, lambda { |i| {:limit => 1, :conditions => ["#{self.table_name}.date < ? and #{self.table_name}.field_id = ?", i.date,i.field_id], :order => "#{self.table_name}.date DESC"} }
  scope :next, lambda { |i| {:limit => 1, :conditions => ["#{self.table_name}.date > ? and #{self.table_name}.field_id = ?", i.date,i.field_id], :order => "#{self.table_name}.date ASC"}}
  
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
    
  def update_balances
    feeld = self.field
    # puts "fdw#update_balances: we (#{self.inspect}) have a field of #{feeld.inspect}";$stdout.flush
    if (self.pred && self.pred.ad)
      previous_ad = self.pred.ad
    elsif feeld.current_crop && feeld.current_crop.emergence_date && self.date == feeld.current_crop.emergence_date
      previous_ad = feeld.initial_ad
    end
    requirements = [ "ref_et", "previous_ad", "feeld", "feeld.field_capacity", "feeld.perm_wilting_pt", "feeld.current_crop", "feeld.current_crop.max_root_zone_depth"]
    errors = []
    requirements.each do |cond|
      unless eval(cond)
        errors << cond
      end
    end
    if errors.size > 0
      logger.info "#{self[:date]} could not update balances.\n  #{self.inspect}\n  #{self.field.inspect}\n  #{self.field.current_crop.inspect}"
      logger.info "   Reasons: " + errors.join(", ")
      return
    end
    return unless self[:adj_et] = feeld.et_method.adj_et(self)
    # puts "update_balances: #{self[:date]} rain #{self[:rain]}, irrigation #{self[:irrigation]}, adj_et #{self[:adj_et]}"
    delta_storage = calc_change_in_daily_storage(self[:rain], self[:irrigation], self[:adj_et])
    # puts "adj_et: #{adj_et} delta_storage: #{delta_storage}" unless adj_et && delta_storage
    total_available_water = calc_taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
    self[:ad] = calc_daily_ad(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
    # puts "\n***** got through update_balance, we're now #{self.inspect}"
  end
  
  def update_next_days_balances
    if self[:ad]
      self.succ.save! if self.succ # triggers the update_balances method
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
  
  def self.page_for(rows_per_page,start_date,date=nil)
    date ||= Date.today
    ((date - start_date) / rows_per_page).to_i
  end
end
