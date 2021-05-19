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
  # GET /fields.xml
  def index
    get_current_ids
    @pivot_id = params[:parent_id]
    @fields = Field.where(:pivot_id => @pivot_id).order(:name) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
    @fields ||= []
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
      columns = COLUMN_NAMES
      format.json do
        json = @fields.to_a.to_jqgrid_json(columns, params[:page], params[:rows], @fields.size)
        render :json => json
      end
    end
  end

  # POST
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
      for col_name in COLUMN_NAMES
        attribs[col_name] = params[col_name] unless col_name == :id || col_name == :act
      end
      if attribs[:soil_type_id]
        attribs[:soil_type_id] = attribs[:soil_type_id].to_i
        attribs[:soil_type_id] = SoilType.default_soil_type[:id] if attribs[:soil_type_id] == 0
      end
      if params[:oper] && params[:oper] == "add"
        attribs[:soil_type_id] = SoilType.default_soil_type[:id] unless attribs[:soil_type_id]
        # Should do a method for this, perhaps with a block for the tests
        attribs[:name] = "New field (pivot #{params[:pivot_id]})" unless (attribs[:name] && attribs[:name] != "")
        attribs[:field_capacity] = SoilType.default_soil_type[:field_capacity] unless attribs[:field_capacity]
        attribs[:perm_wilting_pt] = SoilType.default_soil_type[:perm_wilting_pt] unless attribs[:perm_wilting_pt]
        field = Field.create(attribs)
        field.get_et
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
      :field_capacity_pct => field.field_capacity_pct,
      :perm_wilting_pt_pct => field.perm_wilting_pt_pct
    })
    # puts attrs.inspect
    attrs = ApplicationController.jsonify(attrs)
    render :json => attrs
  end

  def update_target_ad_pct
    field = Field.find(params[:id])
    attribs = { :target_ad_pct => params[:target_ad_pct] }
    field.update(attribs)
    if field.target_ad_in
      tadin_str = sprintf('%0.2f"',field.target_ad_in)
    else
      tadin_str = "none"
    end
    render :json => { :target_ad_pct => params[:target_ad_pct], :target_ad_in => tadin_str }
  end

  # GET /fields/1
  # GET /fields/1.xml
  def show
    @field = Field.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/new
  # GET /fields/new.xml
  def new
    @field = Field.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/1/edit
  def edit
    @field = Field.find(params[:id])
  end

  # POST /fields
  # POST /fields.xml
  def create
    @field = Field.new(params[:field])
    @field.pivot_id = @pivot_id

    respond_to do |format|
      if @field.save
        format.html { redirect_to(@field, :notice => 'Field was successfully created.') }
        format.xml  { render :xml => @field, :status => :created, :location => @field }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fields/1
  # PUT /fields/1.xml
  def update
    @field = Field.find(params[:id])
    @field.pivot_id = @pivot_id

    respond_to do |format|
      if @field.update(params[:field])
        format.html do
          head :ok, content_type: "text/html"
          # redirect_to(@field, :notice => 'Field was successfully updated.')
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @field.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fields/1
  # DELETE /fields/1.xml
  def destroy
    @field = Field.find(params[:id])
    @field.destroy

    respond_to do |format|
      format.html { redirect_to(fields_url) }
      format.xml  { head :ok }
    end
  end


end
