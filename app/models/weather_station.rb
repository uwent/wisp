class WeatherStation < ActiveRecord::Base
  # TODO: Use strong params
  attr_accessible \
    :field_ids,
    :location,
    :name,
    :notes

  belongs_to :group
  has_many :multi_edit_links
  has_many :fields, through: :multi_edit_links
  has_many :weather_station_data

  def has_data_for?(*dates)
    dates.all? do |date|
      weather_station_data.for_date(starts_on).any?
    end
  end

  def ensure_data_for(year)
    starts_on = Date.civil(year,*Field::START_DATE)
    ends_on = Date.civil(year,*Field::END_DATE)

    return if has_data_for?(starts_on, ends_on)

    transaction do
      starts_on.upto(ends_on) do |date|
        weather_station_data.create!(date: date)
      end
    end
  end

  def wx_record_saved(attribs_to_update)
    fields.each do |field|
      begin
        fdw = field.field_daily_weather.select { |fdw| fdw.date.to_s == attribs_to_update[:date].to_s }.first
      rescue NoMethodError => e
        logger.warn "could not find #{attribs_to_update[:date].to_s} record for field #{field[:id]}/#{field.name}"
        next
      end
      unless fdw
        logger.warn "No FDW found for #{attribs_to_update.inspect} in weather_station #{self[:id]}"
        return
      end
      fdw.update_attributes(attribs_to_update) # this will update date too, but no matter, since we're already sure it's the same
      # if user entered a % cover number, send that to all the % cover FDWs affected
      if (attribs_to_update[:entered_pct_cover] && attribs_to_update[:entered_pct_cover] != "")
        if field.et_method == Field::PCT_COVER_METHOD
          fdw.field.pct_cover_changed(fdw)
        end
      end
      fdw.field.save! # Trigger a balance recalc
    end
  end
end
