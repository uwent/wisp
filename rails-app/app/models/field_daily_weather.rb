require 'ad_calculator'
class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  before_create :zero_rain_and_irrig
  before_update :old_update_balances
  after_update :update_next_days_balances
  
  @@debug = nil
  
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
    # TAW(1.0,1.0,1.0)
  end

  # mad_frac: Max allowable depletion as a fraction (0-1.0, usually 0.5)
  # taw: total available water, in inches
  # fc: field capacity, as a fraction
  # ad: current allowable depletion, in inches
  # mrzd: max root zone depth, in inches
  def moisture(mad_frac,taw,pwp,fc,ad,mrzd)
    ad_max = ad_max_inches(mad_frac, taw)
    pct_moisture_from_ad(pwp,fc,ad_max,ad,mrzd)
  end
  
  # TODO: Why does this work, while the one using balance_calcs doesn't? FIXME
  def old_update_balances
    feeld = self.field
    return unless ref_et > 0.0
    (puts "couldn't calculate adj_et";$stdout.flush; return) unless (self[:adj_et] = feeld.et_method.calc_adj_ET(self))
    # puts "fdw#update_balances: we (#{self.inspect}) have a field of #{feeld.inspect}";$stdout.flush
    previous_ad = find_previous_ad
  # puts "Got previous AD of #{previous_ad}"
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
  # puts "update_balances: #{self[:date]} rain #{self[:rain]}, irrigation #{self[:irrigation]}, adj_et #{self[:adj_et]}"
    delta_storage = change_in_daily_storage(self[:rain], self[:irrigation], self[:adj_et])
  # puts "adj_et: #{adj_et} delta_storage: #{delta_storage}"
    total_available_water = taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
    dd = delta_storage + previous_ad
    self[:deep_drainage] = (dd > total_available_water ? dd  - total_available_water : 0.0)
    self[:ad] = daily_ad(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
    self[:calculated_pct_moisture] = moisture(
      feeld.current_crop.max_allowable_depletion_frac,
      total_available_water,
      feeld.perm_wilting_pt,
      feeld.field_capacity,
      self[:ad],
      feeld.current_crop.max_root_zone_depth
    )
    # pct_moisture_from_ad(feeld.perm_wilting_pt, feeld.field_capacity, feeld.current_crop.max_allowable_depletion_frac,
    #   self[:ad], feeld.current_crop.max_root_zone_depth)
  # puts "\n***** got through update_balance, AD is now #{self[:ad]}"
  end
  
  def update_balances
    return unless self[:ref_et]
    balance_calcs.each { |attrib_name,val| self[attrib_name] = val }
  end
  
  def balance_calcs
    # print " #{self.date.yday} "; $stdout.flush
    # deb_puts "balance_calcs for #{self.date} (#{self.field.name})"
    ret = {}
    ret[:adj_et] = field.et_method.calc_adj_ET(self)
    # deb_puts "no adj_et! #{self[:date]}" if ret[:adj_et] == 0.0 or ret[:adj_et] == nil
    previous_ad = find_previous_ad
    # deb_puts "no previous ad" unless previous_ad
    if ret[:adj_et] && previous_ad
      delta_storage = change_in_daily_storage(rain, irrigation, adj_et)
      total_available_water = taw(field.field_capacity, field.perm_wilting_pt, field.current_crop.max_root_zone_depth)
      ret[:deep_drainage] = [0.0,(delta_storage + previous_ad) - total_available_water].max
      ret[:ad] = daily_ad(previous_ad, delta_storage, field.current_crop.max_allowable_depletion_frac, total_available_water)
      ret[:calculated_pct_moisture]= moisture(
        field.current_crop.max_allowable_depletion_frac,
        total_available_water,
        field.perm_wilting_pt,
        field.field_capacity,
        ret[:ad],
        field.current_crop.max_root_zone_depth
      )
    end
    # deb_puts "balance_calcs returning with #{ret.inspect}"
    ret
  end
  
  def update_next_days_balances
    if self[:ad]
      self.succ.save! if self.succ # triggers the update_balances method
    end
    false
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
 
  def find_previous_ad
    feeld = self.field
    if (self.pred && self.pred.ad)
    # puts "previous AD from preceding fdw"
      previous_ad = self.pred.ad
    elsif feeld.current_crop && feeld.current_crop.emergence_date && self.date == feeld.current_crop.emergence_date
    # puts "previous AD from field (we're at the emergence date)"
      previous_ad = feeld.initial_ad
    else
      last_with_ad = FieldDailyWeather.where("field_id = #{field[:id]} and ad is not null").order('date desc').first
      if last_with_ad
      # puts "previous AD some prior record (#{last_with_ad.date})"
        previous_ad = last_with_ad[:ad]
      else
      # puts "previous AD from field (could not find a prior fdw)"
        previous_ad = feeld.initial_ad
      end
    end
    
  end 
  
  # CLASS METHODS
  
  def self.page_for(rows_per_page,start_date,date=nil)
    date ||= Date.today
    # Numb-nuts JS programmers start arrays at 1...
    ((date - start_date) / rows_per_page).to_i + 1
  end
  
  def self.summary(field_id)
    query = <<-END
    select sum(rain) as rain, sum(irrigation) as irrigation, sum(deep_drainage) as deep_drainage
    from field_daily_weather where field_id=#{field_id}
    END
    find_by_sql(query).first
  end

  # Given a subset of FDW data, find the max adj et, and project that outward two days
  # from the last FDW's AD balance
  def self.projected_ad(fdw)
    ret = [0,0]
    return ret unless fdw.size > 0
    max_days_back = -1 * fdw.size
    # find the max adj et for the past two weeks in this field
    max_adj_et = -1000.0
    -1.downto(max_days_back) {|days_back| max_adj_et = [max_adj_et,fdw[days_back].adj_et].max; return ret unless fdw[days_back].ad}
    # since we don't have to worry about any inputs, just subtract from the AD
    [fdw[-1].ad - max_adj_et, fdw[-1].ad - 2*max_adj_et]
  end
  
  
  
  def self.debug_on
    @@debug = true
  end
  
  def deb_puts(something)
    puts something if @@debug
    $stdout.flush
  end
end
