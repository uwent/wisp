class FieldsController < AuthenticatedController
  skip_before_action :verify_authenticity_token, only: :post_data

  COLUMN_NAMES = [
    :name,
    :et_method,
    :area,
    :soil_type_id,
    :field_capacity_pct,
    :perm_wilting_pt_pct,
    :target_ad_pct,
    :ref_et_station_id,
    :rain_station_id,
    :soil_moisture_station_id,
    :notes,
    :act,
    :pivot_id,
    :id
  ]

  # GET /fields
  def index
    return redirect_to "/wisp/pivot_crop" if request.format.html?

    get_current_ids
    @pivot_id = params[:parent_id]
    @fields = Field.where(pivot_id: @pivot_id).order(:name) do
      paginate page: params[:page], per_page: params[:rows]
    end
    @fields ||= []

    render json: @fields.to_a.to_jqgrid_json(COLUMN_NAMES, params[:page], params[:rows], @fields.size)
  rescue => e
    Rails.logger.error "FieldsController :: Index >> #{e.message}"
  end

  # POST /fields/post_data
  def post_data
    @pivot = Pivot.find(params[:pivot_id] || params[:parent_id])
    session[:pivot_id] = params[:pivot_id] || params[:parent_id]
    if params[:oper] == "del"
      field = Field.find(params[:id])
      # check that we're in the right hierarchy, and not some random id
      if field.pivot == @pivot
        field.destroy
        if session[:field_id] == params[:id] # we just destroyed the current field
          session.delete(:field_id)
          get_current_ids
        end
      else
        Rails.logger.warn("FieldsController :: Attempt to destroy field #{params[:id]}, whose pivot #{field.pivot} is not #{@pivot}")
      end
    else
      attribs = {}
      COLUMN_NAMES.each do |col_name|
        attribs[col_name] = params[col_name] unless col_name == :id || col_name == :act
      end
      if attribs[:soil_type_id]
        attribs[:soil_type_id] = attribs[:soil_type_id].to_i
        attribs[:soil_type_id] = SoilType.default_soil_type[:id] if attribs[:soil_type_id] == 0
      end
      if params[:oper] && params[:oper] == "add"
        attribs[:soil_type_id] = SoilType.default_soil_type[:id] unless attribs[:soil_type_id]
        # Should do a method for this, perhaps with a block for the tests
        # attribs[:name] = "New field (pivot #{params[:pivot_id]})" unless attribs[:name] && attribs[:name] != ""
        attribs[:field_capacity] = SoilType.default_soil_type[:field_capacity] unless attribs[:field_capacity]
        attribs[:perm_wilting_pt] = SoilType.default_soil_type[:perm_wilting_pt] unless attribs[:perm_wilting_pt]
        field = Field.create(attribs)
        field.get_et
        field.get_precip
        field.get_degree_days if field.current_crop.plant.uses_degree_days?(field.et_method)
      else
        field = Field.find(params[:id]) # TODO: , :include => :field_daily_weather)
        attribs = field.groom_for_defaults(attribs)
        attribs.delete(:act)
        attribs.delete(:pivot_id) if attribs[:pivot_id]
        # puts "updating field attributes"
        field.update(attribs)
        # puts "field attributes updated"
      end
    end
    attrs = field.attributes.symbolize_keys.merge({
      field_capacity_pct: field.field_capacity_pct,
      perm_wilting_pt_pct: field.perm_wilting_pt_pct
    })
    # puts attrs.inspect
    attrs = ApplicationController.jsonify(attrs)
    render json: attrs
  end

  # this wasn't referenced anywhere in the app
  # def update_target_ad_pct
  #   field = Field.find(params[:id])
  #   attribs = {target_ad_pct: params[:target_ad_pct]}
  #   field.update(attribs)
  #   tadin_str = field.target_ad_in ? sprintf('%0.2f"', field.target_ad_in) : "none"
  #   render json: {target_ad_pct: params[:target_ad_pct], target_ad_in: tadin_str}
  # end
end
