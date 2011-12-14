require 'ad_calculator'

class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  before_create :zero_rain_and_irrig
  before_update :old_update_balances
  after_update :update_next_days_balances, :update_pct_covers
  
  @@debug = nil
  @@do_balances = true
  
  def et_method
    field.et_method
  end
  
  def self.defer_balances
    @@do_balances = false
  end
  
  def self.undefer_balances
    @@do_balances = true
  end
  
  include ADCalculator
  # from the ActsAsAdjacent plugin, which (with this) we don't need
  scope :previous, lambda { |i| {:limit => 1, :conditions => ["#{self.table_name}.date < ? and #{self.table_name}.field_id = ?", i.date,i.field_id], :order => "#{self.table_name}.date DESC"} }
  scope :next, lambda { |i| {:limit => 1, :conditions => ["#{self.table_name}.date > ? and #{self.table_name}.field_id = ?", i.date,i.field_id], :order => "#{self.table_name}.date ASC"}}
  
  def pct_moisture
    entered_pct_moisture || calculated_pct_moisture
  end
  
  def pct_moisture=(moisture)
    self[:entered_pct_moisture] = moisture
    logger.info "I now have an entered pct moisture: "
  end
  
  def pct_cover
    entered_pct_cover || calculated_pct_cover
  end
  
  def entered_pct_cover=(new_value)
    return unless new_value # don't overwrite an entered value, e.g. from mindless grid update
    if read_attribute(:entered_pct_cover) # if we already have a value...(otherwise, just record the new value)
      # check that it's different from existing
      return unless (new_value.to_f - read_attribute(:entered_pct_cover).to_f).abs > 0.00001
    end
    @need_pct_cover_update = true
    write_attribute(:entered_pct_cover,new_value)
  end
  
  # This gets called after we're updated (i.e., the field's array of FDW objects has our new entered_pct_cover value, if any)
  def update_pct_covers
    if @need_pct_cover_update
      @need_pct_cover_update = false
      field.pct_cover_changed(self)
    end
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

  def ad_from_moisture(taw)
    # AD == (moisture - pct_moisture_at_ad_min) * mrzd.
    fc = field.field_capacity
    mrzd = field.current_crop.max_root_zone_depth
    mad_frac = field.current_crop.max_allowable_depletion_frac
    mad_in = ad_max_inches(mad_frac,taw)
    # daily_ad_from_moisture(mad_frac,taw,mrzd,pct_moisture_at_ad_min,entered_pct_moisture)
    # logger.info "ad_from_moisture: #{fc}, #{mad_in}, #{mrzd}, #{pct_moisture}, #{pct_moisture_at_ad_min(fc, mad_in, mrzd)}"
    mrzd * (pct_moisture - pct_moisture_at_ad_min(fc, mad_in, mrzd))/100
  end
  
  # TODO: Why does this work, while the one using balance_calcs doesn't? FIXME
  def old_update_balances
    feeld = self.field
    total_available_water = taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
    if entered_pct_moisture
      self[:calculated_pct_moisture] = entered_pct_moisture
      self[:ad] = [ad_from_moisture(total_available_water),total_available_water].min
      self[:deep_drainage] = (self[:ad] > total_available_water ? self[:ad]  - total_available_water : 0.0)
    else
      return unless ref_et > 0.0
      (puts "couldn't calculate adj_et";$stdout.flush; return) unless (self[:adj_et] = feeld.et_method.adj_et(self))
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
    
      dd = delta_storage + previous_ad
      self[:deep_drainage] = (dd > total_available_water ? dd  - total_available_water : 0.0)
      # FIXME: Entered percent moisture obviates these. Just check that there's a value?
      self[:ad] = daily_ad(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
      self[:calculated_pct_moisture] = moisture(
        feeld.current_crop.max_allowable_depletion_frac,
        total_available_water,
        feeld.perm_wilting_pt,
        feeld.field_capacity,
        self[:ad],
        feeld.current_crop.max_root_zone_depth
      )
    end
  end
  
  def update_balances
    return unless self[:ref_et]
    balance_calcs.each { |attrib_name,val| self[attrib_name] = val }
  end
  
  def balance_calcs
    # print " #{self.date.yday} "; $stdout.flush
    # deb_puts "balance_calcs for #{self.date} (#{self.field.name})"
    ret = {}
    ret[:adj_et] = field.et_method.adj_et(self)
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
    if self[:ad] && @@do_balances
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
  def self.today_or_latest(field_id)
    query = <<-END
      select max(date) as date from field_daily_weather where field_id=#{field_id}
    END
    latest = FieldDailyWeather.find_by_sql(query).first.date
    today = Date.today
    unless latest
      return today
    end
    if today > latest
      return latest
    else
      return today
    end
  end
  
  
  def self.page_for(rows_per_page,start_date,date=nil)
    date ||= today_or_latest(1)
    # Numb-nuts JS programmers start arrays at 1...
    ((date - start_date) / rows_per_page).to_i + 1
  end
  
  def self.summary(field_id)
    query = <<-END
    select sum(rain) as rain, sum(irrigation) as irrigation, sum(deep_drainage) as deep_drainage, sum(adj_et) as adj_et
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
  
  def self.fdw_for(field_id,start_date,end_date)
    where(
      "field_id=? and date >= ? and date <= ?",field_id,start_date,end_date
    ).sort {|fdw,fdw2| fdw[:date] <=> fdw2[:date]}
  end
  
  def self.debug_on
    @@debug = true
  end
  
  def deb_puts(something)
    puts something if @@debug
    $stdout.flush
  end
end
