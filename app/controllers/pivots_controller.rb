class PivotsController < AuthenticatedController
  COLUMN_NAMES = [
    :name,
    :latitude,
    :longitude,
    :equipment,
    :pump_capacity,
    :some_energy_rate_metric,
    :cropping_year,
    :notes,
    :act,
    :farm_id,
    :id
  ]

  # GET /pivots
  def index
    return redirect_to "/wisp/pivot_crop" if request.format.html?

    get_current_ids
    session[:farm_id] = @farm_id
    @farm = current_group.farms.find(@farm_id)
    @pivots = if params[:pivot_id]
      @pivot_id = params[:pivot_id]
      current_group.pivots.where(id: @pivot_id)
    else
      Pivot.where(farm_id: @farm_id).order(:name)
    end
    @paginated_pivots = @pivots.paginate(page: params[:page], per_page: params[:rows])
    json = @paginated_pivots.to_a.to_jqgrid_json(COLUMN_NAMES, params[:page] || 1, params[:rows] || @pivots.size, @pivots.size)
    render json: json
  end

  # POST
  def post_data
    Rails.logger.info("PivotsController :: Pivot post data for farm #{params[:parent_id]}")
    @farm = current_group.farms.find(params[:parent_id])
    session[:farm_id] = params[:parent_id]
    if params[:oper] == "del"
      pivot = @farm.pivots.find(params[:id])
      # check that we're in the right hierarchy, and not some random id
      if pivot.farm == @farm && @farm.pivots.size > 1
        pivot.destroy
      end
    else
      attribs = {}
      COLUMN_NAMES.each do |col_name|
        attribs[col_name] = params[col_name] unless col_name == :id || col_name == :act || col_name == :cropping_year
      end
      if params[:oper] && params[:oper] == "add"
        attribs[:farm_id] = @farm[:id]
        unless attribs[:cropping_year]
          attribs[:cropping_year] = Date.today.year.to_s
        end
        pivot = Pivot.create(attribs)
        Rails.logger.info("PivotsController :: Created the new pivot #{pivot.inspect}")
      else
        attribs.delete(:farm_id) if attribs[:farm_id]
        pivot = current_group.pivots.find(params[:id])
        pivot.update(attribs)
      end
    end
    render json: ApplicationController.jsonify(pivot.attributes)
  end
end
