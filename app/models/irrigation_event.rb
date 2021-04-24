class IrrigationEvent < ApplicationRecord
  belongs_to :pivot, optional: true

  # find the field_daily_weather events that might be affected by us
  def fdw_for(paginate=false)
    res = []
    for field in pivot.fields
      res << field.weather_for(date)
    end
  end
end
