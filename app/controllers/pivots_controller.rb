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
    @farm = Farm.find(@farm_id)
    if params[:pivot_id]
      begin
        @pivot_id = params[:pivot_id]
        @pivots = [Pivot.find(@pivot_id)]
      rescue
        Rails.logger.warn("PivotsController :: Attempt to GET nonexistent pivot #{params[:id]}")
      end
    else
      @pivots = Pivot.where(farm_id: @farm_id).order(:name) do
        paginate page: params[:page], per_page: params[:rows]
      end
    end

    # puts "getting pivots for pivot #{@pivot_id}, found #{@pivots.size} entries"
    @pivots ||= []
    json = @pivots.to_a.to_jqgrid_json(COLUMN_NAMES, params[:page] || 1, params[:rows] || @pivots.size, @pivots.size)
    puts json
    render json: json
  end

  # POST
  def post_data
    Rails.logger.info("PivotsController :: Pivot post data for farm #{params[:parent_id]}")
    @farm = Farm.find(params[:parent_id])
    session[:farm_id] = params[:parent_id]
    if params[:oper] == "del"
      pivot = Pivot.find(params[:id])
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
        attribs[:name] = "New pivot (farm ID: #{@farm[:id]})"
        attribs[:farm_id] = @farm[:id]
        unless attribs[:cropping_year]
          attribs[:cropping_year] = Date.today.year.to_s
        end
        pivot = Pivot.create(attribs)
        Rails.logger.info("PivotsController :: Created the new pivot #{pivot.inspect}")
      else
        attribs.delete(:farm_id) if attribs[:farm_id]
        pivot = Pivot.find(params[:id])
        pivot.update(attribs)
      end
    end
    render json: ApplicationController.jsonify(pivot.attributes)
  end

  # GET /pivots/1
  # GET /pivots/1.xml
  def show
    @pivot = Pivot.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @pivot }
    end
  end

  # GET /pivots/new
  # GET /pivots/new.xml
  def new
    @pivot = Pivot.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @pivot }
    end
  end

  # GET /pivots/1/edit
  def edit
    @pivot = Pivot.find(params[:id])
  end

  # POST /pivots
  # POST /pivots.xml
  def create
    @pivot = Pivot.new(params[:pivot])
    @pivot.farm_id = @farm_id

    respond_to do |format|
      if @pivot.save
        format.html { redirect_to(@pivot, notice: "Pivot was successfully created.") }
        format.xml { render xml: @pivot, status: :created, location: @pivot }
      else
        format.html { render action: "new" }
        format.xml { render xml: @pivot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pivots/1
  # PUT /pivots/1.xml
  def update
    @pivot = Pivot.find(params[:id])
    @pivot.farm_id = @farm_id

    respond_to do |format|
      if @pivot.update(params[:pivot])
        format.html { redirect_to(@pivot, notice: "Pivot was successfully updated.") }
        format.xml { head :ok }
      else
        format.html { render action: "edit" }
        format.xml { render xml: @pivot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pivots/1
  # DELETE /pivots/1.xml
  def destroy
    @pivot = Pivot.find(params[:id])
    @pivot.destroy

    respond_to do |format|
      format.html { redirect_to(pivots_url) }
      format.xml { head :ok }
    end
  end
end
