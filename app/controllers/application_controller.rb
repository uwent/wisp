class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :json_request?
  before_action :set_nav_tabs

  # TODO: Remove this.
  # Implicit conversion of nil into string error with stylesheet tags and content_for, per
  # http://stackoverflow.com/questions/16044008/no-implicit-conversion-of-nil-into-string
  ActionController::Base.config.relative_url_root = ""

  # TODO: Remove this.
  def self.jsonify(hash)
    hash.inject({}) { |ret, entry| ret.merge({entry[0].to_s => entry[1].to_s}) }
  end

  protected

  def json_request?
    request.format.json?
  end

  private

  def set_nav_tabs
    @nav_tabs = [
      {title: "Home", path: "/home", controller: :home, action: :index},
      {title: "Farm Status", path: "/wisp/farm_status", controller: :wisp, action: :farm_status},
      {title: "Pivots/Fields", path: "/wisp/pivot_crop", controller: :wisp, action: :pivot_crop},
      {title: "Field Status", path: "/wisp/field_status", controller: :wisp, action: :field_status},
      {title: "Field Groups", path: "/weather_stations", controller: :weather_stations, action: :index},
      {title: "Edit Daily Data", path: "/wisp/weather", controller: :wisp, action: :weather},
    ].collect do |tab|
      selected = (tab[:controller] == params[:controller]&.to_sym) && (tab[:action] == params[:action]&.to_sym)
      tab[:selected] = selected
      tab
    end
  end


  # TODO: Remove most of this.
  def get_by_parent(klass, parent_klass, parent_id)
    begin
      plural = klass.to_s.downcase + "s"
      parent_obj = parent_klass.find(parent_id)
      obj = eval("parent_obj.#{plural}.first")
      id = obj[:id] if obj
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "ApplicationController :: Parent object find failed for #{klass} / #{parent_klass}:#{parent_id}"
      flash[:notice] = "We're sorry, an internal error has occurred"
      id = obj = nil
    end
    [id, obj]
  end

  def get_and_set(klass, parent_klass, parent_id, preserve_session = nil)
    klassname = klass.to_s.downcase
    sym = (klassname + "_id").to_sym
    id = params[sym] || session[sym]
    if id && id != "" && id.to_i != 0 # This latter in the case of "We don't know what the ID should be"
      # puts "get_and_set: found the id (#{id.inspect}) for #{klass.to_s} in either params (#{params[sym]}) or session (#{session[sym]})"
      # puts "get_and_set: what about string key? (#{params.inspect})"
      begin
        obj = klass.find(id)
      rescue ActiveRecord::RecordNotFound
        # If the object has just been deleted, the find can fail, so fall back to parent's first child
        id, obj = get_by_parent(klass, parent_klass, parent_id)
      end
    else
      id, obj = get_by_parent(klass, parent_klass, parent_id)
    end
    unless preserve_session
      Rails.logger.info "ApplicationController :: Setting session[#{sym}] to #{id}"
      session[sym] = id
    end
    [id, obj]
  end

  def current_group
    @current_group ||= current_user.groups.first
  end

  # TODO: Delete this.
  def get_current_ids
    # Absolute, unchanging:
    @user = current_user
    @user_id = current_user.id
    @group = current_group
    @group_id = @group.id

    @farm = @group.farms.find(params[:farm_id]) if params[:farm_id]
    @farm ||= @group.farms.first

    @farm_id = @farm.id
  end

  def current_day
    # There will always be a field around with field ID 1
    session[:today] || today_or_latest(1)
  end

  # this creates unexpected behavior where the initial date can be in the future and doesn't match what is shown in the data table or the plot (ie before crop emergence)
  def today_or_latest(field_id)
    # field = Field.find(field_id)
    # earliest = field.current_crop.emergence_date
    # query = "select max(date) as date from field_daily_weather where field_id=#{field_id}"
    # latest = FieldDailyWeather.find_by_sql(query).first.date
    day = Date.today
    # day = earliest if day < earliest
    day
  end

  def set_parent_id(attribs, params, parent_id_sym, parent_var)
    parent_id = attribs[parent_id_sym]
    if parent_id.nil? || parent_id == "" || parent_id == "_empty"
      attribs[parent_id_sym] = params[:parent_id] == "" ? parent_var : params[:parent_id]
    end
  end

  # FIXME: Remove the cloning
  # -------------------------
  # Check to see if any of our pivots need to be cloned.
  # def check_pivots_for_cloning(clone_to = nil)
  #   clone_to ||= Time.now.year
  #   return unless current_group
  #   farms = current_group.farms
  #   # What needs cloning? Well, the latest set of pivots whose cropping years are < clone_to
  #   latest_pivots = Farm.latest_pivots(farms)
  #   latest_pivot_year = latest_pivots.first.cropping_year
  #   (latest_pivot_year < clone_to) ? latest_pivots : nil
  # end
end
