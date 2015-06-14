# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable 'FieldDailyWeather'
  inflect.uncountable 'field_daily_weather'
  inflect.uncountable 'WeatherStationData'
  inflect.uncountable 'weather_station_data'
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
end
