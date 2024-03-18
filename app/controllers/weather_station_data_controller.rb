class WeatherStationDataController < AuthenticatedController
  COLUMN_NAMES = [
    :rain,
    :irrigation,
    :entered_pct_moisture,
    :ref_et,
    :entered_pct_cover,
    :notes
  ]
  ROWS_PER_PAGE = 14

  # returns JSON
  def index
    weather_station_id = if params[:weather_station_id]
      params[:weather_station_id].to_i
    else
      @group.weather_stations.first[:id]
    end
    unless @group.weather_stations.detect { |wxs| wxs[:id] == weather_station_id }
      weather_station_id = @group.weather_stations.first[:id]
    end
    @weather_station = WeatherStation.find(weather_station_id)
    @year = params[:year] ? params[:year].to_i : Time.now.year
    wx_start_date, wx_end_date = date_endpoints(@year)

    @weather_data = WeatherStationData.where(weather_station_id: weather_station_id, date: wx_start_date..wx_end_date).order(:date) do
      paginate page: params[:page], per_page: ROWS_PER_PAGE
    end
    # puts "getting wx stn data for #{weather_station_id} #{@year}, found #{@weather_data.size} entries"
    @weather_data ||= []

    render json: @weather_data.to_a.to_jqgrid_json(
      [:date] + COLUMN_NAMES + [:id],
      params[:page],
      params[:rows],
      @weather_data.size
    )
  rescue => e
    Rails.logger.error "WeatherStationDataController :: Index >> #{e}"
    return redirect_to "/wisp/weather_stations"
  end

  # POST
  def post_data
    attribs = {}
    if params[:id]
      wx_rec = WeatherStationData.find(params[:id])
      COLUMN_NAMES.each do |col|
        attribs[col] = params[col] if params[col]
      end
      wx_rec.update(attribs)
    else
      Rails.logger.warn "WeatherStationDataController :: wx stn data post_data attempted without id"
    end
    Rails.logger.info "WeatherStationDataController :: posted data successfully"
    head :ok, content_type: "text/html"
  end

  private

  def date_endpoints(year = nil)
    year ||= Time.now.year
    # puts "date_endpoints: #{year} / #{START_DATE[0]} / #{START_DATE[1]}"
    ep1 = Date.civil(year, *Field::START_DATE)
    ep2 = Date.civil(year, *Field::END_DATE)
    [ep1, ep2]
  end
end
