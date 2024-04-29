module AgWeather
  include HTTParty

  BASE_ENDPOINT = ENV["AG_WEATHER_BASE_URL"]

  ET_ENDPOINT = "#{BASE_ENDPOINT}/evapotranspirations"
  PRECIP_ENDPOINT = "#{BASE_ENDPOINT}/precips"
  DD_ENDPOINT = "#{BASE_ENDPOINT}/degree_days"

  def self.get_et(query)
    fetch(query, ET_ENDPOINT)
  end

  def self.get_precip(query)
    fetch(query, PRECIP_ENDPOINT)
  end

  def self.get_dds(query)
    fetch(query, DD_ENDPOINT)
  end

  def self.fetch(query, endpoint)
    vals = {}
    response = HTTParty.get(endpoint, query: query, timeout: 10)
    json = JSON.parse(response.body, symbolize_names: true)
    json[:data].each do |day|
      vals[day[:date]] = day[:value]
    end
    vals
  rescue => e
    Rails.logger.error "Could not get ET from #{endpoint} with #{query.inspect}"
    {}
  end
end
