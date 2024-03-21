class WeatherStationsController < AuthenticatedController
  expose(:weather_station) { current_group.weather_stations.find(params[:id]) }
  expose(:weather_stations) { current_group.weather_stations }
  expose(:available_fields) { current_group.fields }

  def index
  end

  def show
    redirect_to action: :index
  end

  def new
    @weather_station = current_group.weather_stations.build
    @available_fields = current_group.fields
  end

  def edit
    @weather_station = weather_station
    @available_fields = available_fields
  end

  def create
    @weather_station = WeatherStation.new(weather_station_params)
    @weather_station.group = @group

    if @weather_station.save
      redirect_to action: :index
    else
      render action: "new"
    end
  end

  def update
    @weather_station = WeatherStation.find(params[:id])
    @weather_station.assign_attributes(weather_station_params)
    @weather_station.fields = current_group.fields.where(id: params[:weather_station][:field_ids])

    @weather_station.group = current_group

    if @weather_station.save
      redirect_to action: :index
    else
      render action: "edit"
    end
  end

  def destroy
    @weather_station = current_group.weather_stations.find(params[:id])
    @weather_station.destroy

    redirect_to action: :index, notice: "Successfully deleted field group"
  end

  def weather_station_params
    params.require(:weather_station).permit(:name, :location, :notes, {field_ids: []}, :multi_edit_link)
  end
end
