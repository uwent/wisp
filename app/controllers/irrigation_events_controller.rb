class IrrigationEventsController < AuthenticatedController
  def index
    pivot_id = session[:pivot_id] || session[:pivot_id] = params[:pivot_id]
    @irrig_events = IrrigationEvent.where(:pivot_id => pivot_id).order(:date) do
      paginate :page => params[:page], :per_page => params[:rows]
    end
  # puts "getting irrig events field #{pivot_id}, found #{@irrig_events.size} entries"
    @irrig_events ||= []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @irrig_events }
      format.json { render :json => @irrig_events.to_jqgrid_json([:date,:inches_applied,:id],
                                                             params[:page], params[:rows],@irrig_events.size) }
    end
   end

  def post_data
    raise "Not implemented!"
  end

  # GET /irrigation_events
  # GET /irrigation_events.xml
  def old_index
    @irrigation_events = IrrigationEvent.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @irrigation_events }
    end
  end

  # GET /irrigation_events/1
  # GET /irrigation_events/1.xml
  def show
    @irrigation_event = IrrigationEvent.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @irrigation_event }
    end
  end

  # GET /irrigation_events/new
  # GET /irrigation_events/new.xml
  def new
    @irrigation_event = IrrigationEvent.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @irrigation_event }
    end
  end

  # GET /irrigation_events/1/edit
  def edit
    @irrigation_event = IrrigationEvent.find(params[:id])
  end

  # POST /irrigation_events
  # POST /irrigation_events.xml
  def create
    @irrigation_event = IrrigationEvent.new(params[:irrigation_event])

    respond_to do |format|
      if @irrigation_event.save
        format.html { redirect_to(@irrigation_event, :notice => 'Irrigation event was successfully created.') }
        format.xml  { render :xml => @irrigation_event, :status => :created, :location => @irrigation_event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @irrigation_event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /irrigation_events/1
  # PUT /irrigation_events/1.xml
  def update
    @irrigation_event = IrrigationEvent.find(params[:id])

    respond_to do |format|
      if @irrigation_event.update(params[:irrigation_event])
        format.html { redirect_to(@irrigation_event, :notice => 'Irrigation event was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @irrigation_event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /irrigation_events/1
  # DELETE /irrigation_events/1.xml
  def destroy
    @irrigation_event = IrrigationEvent.find(params[:id])
    @irrigation_event.destroy

    respond_to do |format|
      format.html { redirect_to(irrigation_events_url) }
      format.xml  { head :ok }
    end
  end
end
