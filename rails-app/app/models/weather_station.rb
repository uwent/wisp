class WeatherStation < ActiveRecord::Base
  belongs_to :group
  belongs_to :pivot
  has_many :weather_station_data
  
  def ensure_data_for(year)
    ep1 = Date.civil(year,*Field::START_DATE)
    ep2 = Date.civil(year,*Field::END_DATE)
    # Test that start date and end date are present; ought to be good enough
    unless weather_station_data.detect { |wsd| wsd.date == ep1 } && weather_station_data.detect { |wsd| wsd.date == ep2 }
      for date in ep1..ep2
        logger.info "creating wx stn data for #{date.to_s}"
        weather_station_data << WeatherStationData.new(:date => date)
      end
      save!
    end
  end
  
  def wx_record_saved(attribs_to_update)
    if pivot
      pivot.fields.each do |field|
        begin
          fdw = field.field_daily_weather.select { |fdw| fdw.date.to_s == attribs_to_update[:date].to_s }.first
        rescue NoMethodError => e
          logger.warn "could not find #{attribs_to_update[:date].to_s} record for field #{field[:id]}/#{field.name}"
          next
        end
        fdw.update_attributes(attribs_to_update) # this will update date too, but no matter, since we're already sure it's the same
      end
    else
      logger.warn "WeatherStation#wx_record_saved: station #{self[:id]}, #{self.name} has no pivot!"
    end
  end
end
