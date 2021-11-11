class CropsController < AuthenticatedController
  # TODO: Remove this.
  # before_filter(:only => [:post_data, :show, :edit, :update, :destroy]) {|controller| @crop = Crop.find(params[:id]) if (params[:id] && params[:id] != '_empty')}
  before_action(only: [:post_data, :show, :edit, :update, :destroy]) { |controller| @crop = Crop.find(params[:id]) if params[:id] && params[:id] != "_empty" }

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
  # GET /crops.xml
  def index
    get_current_ids

    @field = @group.fields.find(params[:parent_id])
    @farm = @field.pivot_farm
    # @farm_id = @farm_id

    @crop = @field.crops.first!
    @crops = [@crop]
    @crop_id = @crop.id

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @crops }
      columns = COLUMN_NAMES
      columns << :id
      columns << :field_id
      format.json {
        render json: @crops.to_a.to_jqgrid_json(columns, params[:page], params[:rows], @crops.size)
      }
    end
  end

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

  # GET /crops/1
  # GET /crops/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @crop }
    end
  end

  # GET /crops/new
  # GET /crops/new.xml
  def new
    @crop = Crop.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @crop }
    end
  end

  # GET /crops/1/edit
  def edit
  end

  # POST /crops
  # POST /crops.xml
  def create
    @crop = Crop.new(params[:crop])
    @crop.field_id = @field_id

    respond_to do |format|
      if @crop.save
        format.html { redirect_to(@crop, notice: "Crop was successfully created.") }
        format.xml { render xml: @crop, status: :created, location: @crop }
      else
        format.html { render action: "new" }
        format.xml { render xml: @crop.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /crops/1
  # PUT /crops/1.xml
  def update
    @crop.field_id = @field_id

    respond_to do |format|
      if @crop.update(params[:crop])
        format.html { redirect_to(@crop, notice: "Crop was successfully updated.") }
        format.xml { head :ok }
      else
        format.html { render action: "edit" }
        format.xml { render xml: @crop.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crops/1
  # DELETE /crops/1.xml
  def destroy
    @crop.destroy

    respond_to do |format|
      format.html { redirect_to(crops_url) }
      format.xml { head :ok }
    end
  end

  private

  # def get_current_ids
  #   logger.info "crops_controller#get_current_ids: session is #{session.inspect}"
  #   group = @user.groups.first
  #   @farm_id = params[:farm_id] || session[:farm_id] || Farm.my_farms(group[:id]).first # what to do if no farms yet?
  #   @pivot_id = params[:pivot_id] || session[:pivot_id]
  #   @field_id = params[:field_id] || session[:field_id]
  # end
end
