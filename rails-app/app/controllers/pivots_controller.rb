class PivotsController < ApplicationController
  before_filter :ensure_signed_in, :current_user, :get_current_farm # sets @farm_id
  
  # GET /pivots
  # GET /pivots.xml
  def index
    @pivots = Pivot.find(:all, :conditions => ['farm_id = ?', @farm_id])
    session[:farm_id] = @farm_id
    @farm = Farm.find(@farm_id)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pivots }
    end
  end

  # GET /pivots/1
  # GET /pivots/1.xml
  def show
    @pivot = Pivot.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @pivot }
    end
  end

  # GET /pivots/new
  # GET /pivots/new.xml
  def new
    @pivot = Pivot.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pivot }
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
        format.html { redirect_to(@pivot, :notice => 'Pivot was successfully created.') }
        format.xml  { render :xml => @pivot, :status => :created, :location => @pivot }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pivot.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pivots/1
  # PUT /pivots/1.xml
  def update
    @pivot = Pivot.find(params[:id])
    @pivot.farm_id = @farm_id

    respond_to do |format|
      if @pivot.update_attributes(params[:pivot])
        format.html { redirect_to(@pivot, :notice => 'Pivot was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pivot.errors, :status => :unprocessable_entity }
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
      format.xml  { head :ok }
    end
  end
  
  private
  def get_current_farm
    @group = @current_user.groups.first
    @farm_id = params[:farm_id] || session[:farm_id]
    if @farm_id
      @farm = Farm.find(@farm_id)
    else
      @farm = Farm.my_farms(@group[:id]).first
      @farm_id = @farm[:id]
    end
    @farms = Farm.where(:group_id => @group[:id])
    
  end
end
