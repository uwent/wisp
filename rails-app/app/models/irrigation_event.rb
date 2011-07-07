class IrrigationEvent < ActiveRecord::Base
  belongs_to :pivot
  
  # find the field_daily_weather events that might be affected by us
  def fdw_for(paginate=false)
  end
end
