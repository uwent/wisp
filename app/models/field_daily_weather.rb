class FieldDailyWeather < ApplicationRecord
  belongs_to :field, optional: true
  before_create :zero_rain_and_irrig
  before_save :set_adj_et

  SEASON_DAYS = 244
  REF_ET_EPSILON = 0.00001

  @@debug = nil
  @@do_balances = true

  def et_method
    field.et_method
  end

  # TODO: Get rid of this
  def self.defer_balances
    @@do_balances = false
  end

  # TODO: Get rid of this
  def self.undefer_balances
    @@do_balances = true
  end

  include ADCalculator
  # from the ActsAsAdjacent plugin, which (with this) we don't need
  scope :previous, lambda { |i| {limit: 1, conditions: ["#{table_name}.date < ? and #{table_name}.field_id = ?", i.date, i.field_id], order: "#{table_name}.date DESC"} }
  scope :next, lambda { |i| {limit: 1, conditions: ["#{table_name}.date > ? and #{table_name}.field_id = ?", i.date, i.field_id], order: "#{table_name}.date ASC"} }

  def pct_moisture
    entered_pct_moisture || calculated_pct_moisture
  end

  def display_pct_moisture
    entered_pct_moisture ? entered_pct_moisture.to_s + "E" : calculated_pct_moisture
  end

  def pct_moisture=(moisture)
    self[:entered_pct_moisture] = moisture
    Rails.logger.info "FieldDailyWeather :: I now have an entered pct moisture: #{moisture}"
  end

  def adj_et_for_json
    if entered_pct_moisture
      "n/a"
    else
      self[:adj_et]
    end
  end

  def pct_cover
    entered_pct_cover || calculated_pct_cover
  end

  def pct_cover_for_json
    if entered_pct_cover
      entered_pct_cover.to_s + "E"
    else
      calculated_pct_cover
    end
  end

  def entered_pct_cover=(new_value)
    return unless new_value # don't overwrite an entered value, e.g. from mindless grid update
    if read_attribute(:entered_pct_cover) # if we already have a value...(otherwise, just record the new value)
      # check that it's different from existing
      return unless (new_value.to_f - read_attribute(:entered_pct_cover).to_f).abs > 0.00001
    end
    @need_pct_cover_update = true
    write_attribute(:entered_pct_cover, new_value)
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
  def moisture(mad_frac, taw, pwp, fc, ad, mrzd)
    ad_max = ad_max_inches(mad_frac, taw)
    pct_moisture_from_ad(pwp, fc, ad_max, ad, mrzd)
  end

  def ad_from_moisture(taw, fc = field.field_capacity)
    raise "need field capacity for #{self[:id]}; field is #{field.inspect}" unless fc
    mrzd = field.current_crop.max_root_zone_depth
    mad_frac = field.current_crop.max_allowable_depletion_frac
    mad_in = ad_max_inches(mad_frac, taw)
    # daily_ad_from_moisture(mad_frac,taw,mrzd,pct_moisture_at_ad_min,entered_pct_moisture)
    # puts "ad_from_moisture (#{date}): fc #{fc}, ad_max_inches #{mad_in}, mrzd #{mrzd}, pct_moisture #{pct_moisture}, pct_moisture at min ad #{pct_moisture_at_ad_min(fc, mad_in, mrzd)}"
    mrzd * (pct_moisture - pct_moisture_at_ad_min(fc, mad_in, mrzd)) / 100
  end

  def set_ad_from_calculated_moisture(fc, pwp, mrzd)
    total_available_water = taw(fc, pwp, mrzd)
    self[:ad] = [ad_from_moisture(total_available_water, fc), total_available_water].min
    # puts "set ad from calculated moisture: fc #{fc}, pwp #{pwp}, mrzd #{mrzd}, mad_frac #{field.current_crop.max_allowable_depletion_frac}, new ad #{self[:ad]}"
    self[:deep_drainage] = ((self[:ad] > total_available_water) ? self[:ad] - total_available_water : 0.0)
  end

  # if we have the wherewithal and the adj_et is 0.0 or nil, calculate it
  def set_adj_et
    unless adj_et && adj_et > 0.0
      # Rails.logger.warn "setting adj_et for #{date} to #{field.adj_et(self)}, was #{adj_et}"
      self[:adj_et] = field.adj_et(self)
    end
  end

  # TODO: Why does this work, while the one using balance_calcs doesn't? FIXME
  def old_update_balances(previous_ad = nil, previous_max_adj_et = nil)
    return unless @@do_balances
    feeld = field
    total_available_water = taw(feeld.field_capacity, feeld.perm_wilting_pt, feeld.current_crop.max_root_zone_depth)
    if entered_pct_moisture
      self[:calculated_pct_moisture] = entered_pct_moisture
      self[:ad] = [ad_from_moisture(total_available_water), total_available_water].min
      self[:deep_drainage] = ((self[:ad] > total_available_water) ? self[:ad] - total_available_water : 0.0)
      # Rails.logger.info "#{self[:date]}: Deep drainage #{self[:deep_drainage]} from entered moisture of #{entered_pct_moisture}" if self[:deep_drainage] > 0.0
    else
      return unless ref_et || previous_max_adj_et
      unless (self[:adj_et] = feeld.adj_et(self))
        Rails.logger.warn "FieldDailyWeather :: #{date}: couldn't calculate adj_et out of ref_et #{ref_et} pct c #{pct_cover} lai #{leaf_area_index}"
        # FIXME: Why was this "return" here? Shouldn't it fall through to code just below?
        # return
      end
      # If ref_et is zero (i.e. missing) and we have a previous adjusted ET use that instead.
      # This should work for both gaps in the reference ET record and for extrapolations.
      if (self[:ref_et] < REF_ET_EPSILON) && previous_max_adj_et
        self[:adj_et] = previous_max_adj_et
        # Rails.logger.info "#{date}: used previous_max_adj_et: #{self[:adj_et]},"; $stdout.flush
      end

      # Rails.logger.info "fdw#update_balances: date #{date} ref_et #{ref_et} adj_et #{adj_et}"
      previous_ad ||= find_previous_ad
      # puts "Got previous AD of #{previous_ad}"
      requirements = ["ref_et", "previous_ad", "feeld", "feeld.field_capacity", "feeld.perm_wilting_pt", "feeld.current_crop", "feeld.current_crop.max_root_zone_depth"]
      errors = []
      requirements.each do |cond|
        unless eval(cond)
          errors << cond
        end
      end
      if errors.size > 0
        Rails.logger.info "FieldDailyWeather :: #{self[:date]} could not update balances.\n  #{inspect}\n  #{field.inspect}\n  #{field.current_crop.inspect}"
        Rails.logger.info "   Reasons: " + errors.join(", ")
        return
      end
      # puts "update_balances: #{self[:date]} rain #{self[:rain]}, irrigation #{self[:irrigation]}, adj_et #{self[:adj_et]}"
      delta_storage = change_in_daily_storage(self[:rain], self[:irrigation], self[:adj_et])
      # puts "adj_et: #{adj_et} delta_storage: #{delta_storage}"

      ad, dd = daily_ad_and_dd(previous_ad, delta_storage, feeld.current_crop.max_allowable_depletion_frac, total_available_water)
      # coerce AD to be no lower than water in inches at PWP
      ad = [ad, ad_inches_at_pwp(total_available_water, feeld.current_crop.max_allowable_depletion_frac)].max
      self[:ad], self[:deep_drainage] = [ad, dd]

      # FIXME: why any at all?
      self[:deep_drainage] = 0.0 if self[:deep_drainage] < 0.01
      # dbg = "#{self[:date]}: Deep drainage of #{self[:deep_drainage]} from prev ad #{previous_ad}, delta #{delta_storage}, taw #{total_available_water}"
      # Rails.logger.info("FieldDailyWeather :: " + dbg) if self[:deep_drainage] > 0
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

  def update_next_days_balances
    if self[:ad] && @@do_balances
      succ&.save! # triggers the update_balances method
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
    feeld = field
    if pred&.ad
      # puts "previous AD from preceding fdw"
      previous_ad = pred.ad
    elsif feeld&.current_crop&.emergence_date == date
      # puts "previous AD from field (we're at the emergence date)"
      previous_ad = feeld.initial_ad
    else
      last_with_ad = FieldDailyWeather.where("field_id = #{field[:id]} and ad is not null").order("date desc").first
      previous_ad = last_with_ad ? last_with_ad[:ad] : feeld.initial_ad
    end
    previous_ad
  end

  # CLASS METHODS
  def self.today_or_latest(field_id)
    # query = <<-END
    #   select max(date) as date from field_daily_weather where field_id=#{field_id}
    # END
    # latest = FieldDailyWeather.find_by_sql(query).first.date
    latest = FieldDailyWeather.where(field_id: field_id).maximum(:date)
    today = Date.today
    unless latest
      return today
    end
    if today > latest
      latest
    else
      today
    end
  end

  def self.page_for(rows_per_page, start_date, date = nil)
    date ||= today_or_latest(1)
    # Numb-nuts JS programmers start arrays at 1...
    ((date - start_date) / rows_per_page).to_i + 1
  end

  def self.summary(field_id, start_date = nil, finish_date = nil)
    field = Field.find(field_id)
    season_year = field.current_crop.emergence_date.year
    # start at supplied start date, or at emergence
    start_date ||= field.current_crop.emergence_date
    kill_date = field.current_crop.harvest_or_kill_date
    # If a date was supplied, coerce it to be in the same year as season_year
    if finish_date
      if finish_date.year != season_year
        finish_date = Date.new(season_year, finish_date.month, finish_date.mday)
      end
    else
      # If not supplied, finish_date defaults to:
      # 1) today if in current year and earlier than harvest/kill date,
      # 2) harvest/kill date if specified and is prior to today,
      # 3) end of data if earlier than today or harvest/kill
      # FIXME: What if today is after the current
      today = Date.today
      last_data_date = Date.new(season_year, Field::END_DATE[0], Field::END_DATE[1])
      kill_date ||= last_data_date

      # use today, or kill date or the end of season, whichever is earliest
      finish_date ||= if today.year == season_year
        [today, kill_date, last_data_date].min
      else
        [kill_date, last_data_date].min
      end
    end
    cols = [:rain, :irrigation, :deep_drainage, :ref_et, :adj_et]
    vals = FieldDailyWeather.where(date: start_date..finish_date, field_id: field_id)
      .pluck("sum(rain), sum(irrigation), sum(deep_drainage), sum(ref_et), sum(adj_et)")
      .first
    hash = cols.zip(vals).to_h
    hash[:date] = finish_date
    hash
  end

  def self.fdw_for(field_id, start_date, end_date)
    where("field_id=? and date >= ? and date <= ?", field_id, start_date, end_date)
      .sort_by { |a| a[:date] }
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
    case et_method
    when Field::PCT_COVER_METHOD
      ["Percent Cover", :pct_cover]
    when Field::LAI_METHOD
      ["Leaf Area Index", :leaf_area_index]
    end
  end

  def csv_cols
    # cols = attributes.merge(balance_calcs).keys
    # REPORT_COLS_TO_IGNORE.each { |rcti| cols.delete(rcti) }
    # cols
    [
      ["Date", :date],
      ["Potential ET", :ref_et],
      ["AD", :ad],
      ["Percent Moisture", :pct_moisture],
      cover_param,
      ["Rainfall", :rain],
      ["Irrigation", :irrigation],
      ["Adjusted ET", :adj_et],
      ["Deep Drainage", :deep_drainage]
    ]
  end

  def to_csv
    keys = csv_cols.collect { |arr| arr[1].to_s }
    ret = []
    keys.each do |key|
      obj = attributes[key] || send(key)
      ret << if obj
        if obj.instance_of?(Float)
          sprintf("%0.4f", obj)
        elsif obj.instance_of?(ActiveSupport::TimeWithZone) || obj.instance_of?(Date) || obj.instance_of?(Time)
          obj.strftime("%Y-%m-%d")
        elsif obj.is_a?(Integer)
          obj.to_s
        else
          "'#{obj}'"
        end
      else
        ""
      end
    end
    ret.join(",")
  end
end
