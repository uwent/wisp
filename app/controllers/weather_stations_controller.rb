class WeatherStationsController < AuthenticatedController
  # TODO: Install decent_exposure
  # expose(:weather_station) { current_group.weather_stations.find(params[:id]) }
  # expose(:weather_stations) { current_group.weather_stations }
  # expose(:available_fields) { current_group.fields }

  def index
    respond_to do |format|
      format.html
      format.xml { render xml: weather_stations }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml { render xml: weather_station }
    end
  end

  def new
    weather_station = current_group.weather_stations.build

    respond_to do |format|
      format.html
      format.xml { render xml: weather_station }
    end
  end

  def edit
  end

  def create
    @weather_station = WeatherStation.new(params[:weather_station])
    @weather_station.group = @group

    respond_to do |format|
      if @weather_station.save
        format.html { redirect_to(@weather_station, :notice => 'Weather station was successfully created.') }
        format.xml  { render :xml => @weather_station, :status => :created, :location => @weather_station }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @weather_station.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @weather_station = WeatherStation.find(params[:id])
    params[:weather_station][:group_id] = @group[:id]
    respond_to do |format|
      if @weather_station.update_attributes(params[:weather_station])
        format.html { redirect_to(action: :index, :notice => 'Weather station was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @weather_station.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @weather_station = WeatherStation.find(params[:id])
    if @weather_station.group == @group
      @weather_station.destroy
    end

    respond_to do |format|
      format.html { redirect_to(weather_stations_url) }
      format.xml  { head :ok }
    end
  end
end
