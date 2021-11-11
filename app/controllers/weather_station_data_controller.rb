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

  # GET /weather_station_data
  # GET /weather_station_data.xml
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

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @weather_data }
      format.json {
        render json: @weather_data.to_a.to_jqgrid_json(
          [:date] + COLUMN_NAMES + [:id],
          params[:page],
          params[:rows],
          @weather_data.size
        )
      }
    end
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
      logger.warn("WeatherStationDataController :: wx stn data post_data attempted without id")
    end
    logger.info("WeatherStationDataController :: posted data successfully")
    head :ok, content_type: "text/html"
  end

  # GET /weather_station_data/1
  # GET /weather_station_data/1.xml
  def show
    @weather_station_data = WeatherStationData.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @weather_station_data }
    end
  end

  # GET /weather_station_data/new
  # GET /weather_station_data/new.xml
  def new
    @weather_station_data = WeatherStationData.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @weather_station_data }
    end
  end

  # GET /weather_station_data/1/edit
  def edit
    @weather_station_data = WeatherStationData.find(params[:id])
  end

  # POST /weather_station_data
  # POST /weather_station_data.xml
  def create
    @weather_station_data = WeatherStationData.new(params[:weather_station_data])

    respond_to do |format|
      if @weather_station_data.save
        format.html { redirect_to(@weather_station_data, notice: "Field group was successfully created.") }
        format.xml { render xml: @weather_station_data, status: :created, location: @weather_station_data }
      else
        format.html { render action: "new" }
        format.xml { render xml: @weather_station_data.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /weather_station_data/1
  # PUT /weather_station_data/1.xml
  def update
    @weather_station_data = WeatherStationData.find(params[:id])

    respond_to do |format|
      if @weather_station_data.update(params[:weather_station_data])
        format.html { redirect_to(@weather_station_data, notice: "Field group successfully updated.") }
        format.xml { head :ok }
      else
        format.html { render action: "edit" }
        format.xml { render xml: @weather_station_data.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weather_station_data/1
  # DELETE /weather_station_data/1.xml
  def destroy
    @weather_station_data = WeatherStationData.find(params[:id])
    @weather_station_data.destroy

    respond_to do |format|
      format.html { redirect_to(weather_station_data_url) }
      format.xml { head :ok }
    end
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
