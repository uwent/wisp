class FieldDailyWeather < ActiveRecord::Base
  belongs_to :field
  before_create :zero_rain_and_irrig
  # before_update :old_update_balances
  # after_update :update_next_days_balances, :update_pct_covers
  
  SEASON_DAYS = 183
  ADJ_ET_EPSILON = 0.00001
  
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
  
  def display_pct_moisture
    entered_pct_moisture ? entered_pct_moisture.to_s + 'E' : calculated_pct_moisture
  end
  
  def pct_moisture=(moisture)
    self[:entered_pct_moisture] = moisture
    logger.info "I now have an entered pct moisture: #{moisture}"
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

  def ad_from_moisture(taw,fc=field[:field_capacity])
    raise "need field capacity for #{self[:id]}; field is #{field.inspect}" unless fc
    mrzd = field.current_crop.max_root_zone_depth
    mad_frac = field.current_crop.max_allowable_depletion_frac
    mad_in = ad_max_inches(mad_frac,taw)
    # daily_ad_from_moisture(mad_frac,taw,mrzd,pct_moisture_at_ad_min,entered_pct_moisture)
    # puts "ad_from_moisture (#{date}): fc #{fc}, ad_max_inches #{mad_in}, mrzd #{mrzd}, pct_moisture #{pct_moisture}, pct_moisture at min ad #{pct_moisture_at_ad_min(fc, mad_in, mrzd)}"
    mrzd * (pct_moisture - pct_moisture_at_ad_min(fc, mad_in, mrzd))/100
  end
  
  def set_ad_from_calculated_moisture(fc,pwp,mrzd)
    total_available_water = taw(fc, pwp, mrzd)
    self[:ad] = [ad_from_moisture(total_available_water,fc),total_available_water].min
    # puts "set ad from calculated moisture: fc #{fc}, pwp #{pwp}, mrzd #{mrzd}, mad_frac #{field.current_crop.max_allowable_depletion_frac}, new ad #{self[:ad]}"
    self[:deep_drainage] = (self[:ad] > total_available_water ? self[:ad]  - total_available_water : 0.0)
  end
  
  # TODO: Why does this work, while the one using balance_calcs doesn't? FIXME
  def old_update_balances(previous_ad=nil,previous_max_adj_et=nil)
    return unless @@do_balances
    feeld = self.field
    total_available_water = taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
    if entered_pct_moisture
      self[:calculated_pct_moisture] = entered_pct_moisture
      self[:ad] = [ad_from_moisture(total_available_water),total_available_water].min
      self[:deep_drainage] = (self[:ad] > total_available_water ? self[:ad]  - total_available_water : 0.0)
      logger.info "#{self[:date]}: Deep drainage #{self[:deep_drainage]} from entered moisture of #{entered_pct_moisture}" if self[:deep_drainage] > 0.0
    else
      return unless ref_et || previous_max_adj_et
      unless (self[:adj_et] = feeld.et_method.adj_et(self))
        logger.warn "#{self.inspect } couldn't calculate adj_et"
        return
      end
      # If adj_et is zero and we have a previous, use that instead
      if (self[:adj_et] < ADJ_ET_EPSILON) && previous_max_adj_et
        self[:adj_et] = previous_max_adj_et
        # print "#{self[:adj_et]},"; $stdout.flush 
      end
      
      # puts "fdw#update_balances: date #{date} ref_et #{ref_et} adj_et #{adj_et}" if (date >= Date.parse('2011-06-01') && date <= Date.parse('2011-06-20'))
      previous_ad ||= find_previous_ad
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
      
      # Should check that AD doesn't go any lower than PWP
      self[:ad],self[:deep_drainage] = daily_ad_and_dd(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
      
      #FIXME: why any at all?
      self[:deep_drainage] = 0.0 if self[:deep_drainage] < 0.01
      dbg = <<-END
      #{self[:date]}: Deep drainage of #{self[:deep_drainage]} from prev ad #{previous_ad}, delta #{delta_storage}, taw #{total_available_water}
      END
      logger.info dbg if self[:deep_drainage] > 0
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
  
  # def update_balances
  #   return unless self[:ref_et]
  #   balance_calcs.each { |attrib_name,val| self[attrib_name] = val }
  # end
  # 
  # def balance_calcs
  #   # print " #{self.date.yday} "; $stdout.flush
  #   # deb_puts "balance_calcs for #{self.date} (#{self.field.name})"
  #   ret = {}
  #   ret[:adj_et] = field.et_method.adj_et(self)
  #   previous_ad = find_previous_ad
  #   # deb_puts "no previous ad" unless previous_ad
  #   if ret[:adj_et] && previous_ad
  #     delta_storage = change_in_daily_storage(rain, irrigation, adj_et)
  #     total_available_water = taw(field.field_capacity, field.perm_wilting_pt, field.current_crop.max_root_zone_depth)
  #     ret[:deep_drainage] = [0.0,(delta_storage + previous_ad) - total_available_water].max
  #     ret[:ad] = daily_ad(previous_ad, delta_storage, field.current_crop.max_allowable_depletion_frac, total_available_water)
  #     ret[:calculated_pct_moisture]= moisture(
  #       field.current_crop.max_allowable_depletion_frac,
  #       total_available_water,
  #       field.perm_wilting_pt,
  #       field.field_capacity,
  #       ret[:ad],
  #       field.current_crop.max_root_zone_depth
  #     )
  #   end
  #   # deb_puts "balance_calcs returning with #{ret.inspect}"
  #   ret
  # end
  
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
  
  def self.summary(field_id,start_date=nil,finish_date=nil)
    field = Field.find(field_id)
    season_year = field.current_crop.emergence_date.year
    # start at supplied start date, or at emergence
    start_date ||= field.current_crop.emergence_date
    # If a date was supplied, coerce it to be in the same year as season_year
    if finish_date
      if finish_date.year != season_year
        finish_date = Date.new(season_year,finish_date.month,finish_date.mday)
      end
    else
      # If not supplied, finish_date defaults to today if in current year, end of season otherwise
      # FIXME: What if today is after the current 
      today = Date.today
      if today.year == season_year
        # use today, or the end of season, whichever is earliest
        today = [today,Date.new(season_year,Field::END_DATE[0],Field::END_DATE[1])].min
        finish_date ||= today
      else
        finish_date ||= Date.new(season_year,Field::END_DATE[0],Field::END_DATE[1])
      end
    end
    query = <<-END
    select '#{finish_date}' as date, sum(rain) as rain, sum(irrigation) as irrigation, sum(deep_drainage) as deep_drainage, sum(adj_et) as adj_et
    from field_daily_weather where field_id=#{field_id} and date >= '#{start_date}' and date <= '#{finish_date}'
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
  
  REPORT_COLS_TO_IGNORE = ["id", "created_at", "updated_at"]

  def cover_param
    case et_method[:type]
    when 'PctCoverEtMethod'
      ['Percent Cover',:pct_cover]
    when 'LaiEtMethod'
      ['Leaf Area Index', :leaf_area_index]
    end
  end
  
  def csv_cols
    # cols = attributes.merge(balance_calcs).keys
    # REPORT_COLS_TO_IGNORE.each { |rcti| cols.delete(rcti) }
    # cols
    [['Date',:date],['Reference ET',:ref_et],['AD',:ad],['Percent Moisture',:pct_moisture],cover_param,['Rainfall',:rain],['Irrigation',:irrigation],['Adjusted ET',:adj_et],['Deep Drainage',:deep_drainage]]
  end

  def to_csv
    keys = csv_cols.collect { |arr| arr[1].to_s }
    ret = []
    keys.each do |key|
      obj = attributes[key] || self.send(key)
      if obj
        if obj.class == Float
          ret << sprintf('%0.2f',obj)
        elsif obj.class == ActiveSupport::TimeWithZone || obj.class == Date || obj.class == Time
          ret << obj.strftime("%Y-%m-%d")
        elsif obj.kind_of?(Fixnum)
          ret << obj.to_s
        else
          ret << "'#{obj.to_s}'"
        end
      else
        ret << ""
      end
    end
    ret.join(",")
  end
end
