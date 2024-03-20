class CropsController < AuthenticatedController
  before_action(only: [:post_data]) { |controller| @crop = Crop.find(params[:id]) if params[:id] && params[:id] != "_empty" }

  COLUMN_NAMES = [
    :name,
    :plant_id,
    :variety,
    :emergence_date,
    :harvest_or_kill_date,
    :max_root_zone_depth,
    :max_allowable_depletion_frac,
    :notes
  ]

  # GET /crops
  def index
    # only JSON format allowed
    return redirect_to "/wisp/pivot_crop" if request.format.html?

    get_current_ids
    @field = @group.fields.find(params[:parent_id])
    @farm = @field.pivot_farm
    @crop = @field.crops.first!
    @crops = [@crop]
    @crop_id = @crop.id
    columns = COLUMN_NAMES
    columns << :id
    columns << :field_id

    render json: @crops.to_a.to_jqgrid_json(columns, params[:page], params[:rows], @crops.size)
  rescue => e
    Rails.logger.error "CropsController :: index >> #{e.message}"
  end

  # handle crop actions
  def post_data
    @field = Field.find(params[:parent_id])
    session[:field_id] = params[:parent_id]
    if params[:oper] == "del"
      # crop = Crop.find(params[:id])
      # probably should call auth here, but let's just let it slide for now
      @crop.destroy
      if session[:crop_id] == params[:id] # we just destroyed the current crop
        session.delete(:crop_id)
        get_current_ids
      end
    else
      attribs = {}
      COLUMN_NAMES.each do |col_name|
        attribs[col_name] = params[col_name] unless col_name == :id
      end
      if params[:oper] == "add"
        set_parent_id(attribs, params, :field_id, @field_id)
        Crop.create(attribs)
      else
        @crop.update(attribs)
      end
    end
    head :ok, content_type: "text/html"
  end
end
