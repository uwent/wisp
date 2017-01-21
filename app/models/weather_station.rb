class WeatherStation < ActiveRecord::Base
  belongs_to :group
  has_many :multi_edit_links, dependent: :destroy
  has_many :fields, through: :multi_edit_links
  has_many :weather_station_data, dependent: :destroy
  has_many :field_daily_weather, through: :fields

  def has_data_for?(*dates)
    dates.all? do |date|
      weather_station_data.for_date(date).any?
    end
  end

  def ensure_data_for(year)
    starts_on = Field.starts_on(year)
    ends_on = Field.ends_on(year)

    return if has_data_for?(starts_on, ends_on)

    transaction do
      starts_on.upto(ends_on) do |date|
        weather_station_data.where(date: date).first_or_create!
      end
    end
  end

  def wx_record_saved(attributes)
    fields.each do |field|
      fdw = field.field_daily_weather.where(date: attributes[:date]).first

      # TODO: More verbose logging or is this actually an exception?
      next unless fdw

      # TODO: Should probably be update_attributes!
      # TODO: with_indifferent_access
      fdw.update_attributes(attributes.except(:date))

      # if user entered a % cover number,
      # send that to all the % cover FDWs affected
      if (attributes[:entered_pct_cover].present?)
        if field.et_method == Field::PCT_COVER_METHOD
          fdw.field.pct_cover_changed(fdw)
        end
      end
      fdw.field.save! # Trigger a balance recalc
    end
  end

  def new_year
    self.weather_station_data = []
  end
end
