class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # TODO: Remove this.
  # Implicit conversion of nil into string error with stylesheet tags and content_for, per
  # http://stackoverflow.com/questions/16044008/no-implicit-conversion-of-nil-into-string
  ActionController::Base.config.relative_url_root = ''

  # TODO: Remove this.
  def self.jsonify(hash)
    hash.inject({}) {|ret,entry| ret.merge({entry[0].to_s => entry[1].to_s})}
  end

  private
  # TODO: Remove most of this.
  def get_by_parent(klass,parent_klass,parent_id)
    begin
      plural = klass.to_s.downcase + 's'
      parent_obj = parent_klass.find(parent_id)
      obj = eval("parent_obj.#{plural}.first")
      id = obj[:id] if obj
    rescue ActiveRecord::RecordNotFound => e
      logger.error "Parent object find failed for #{klass.to_s} / #{parent_klass.to_s}:#{parent_id}"
      flash[:notice] = "We're sorry, an internal error has occurred"
      id = obj = nil
    end
    [id,obj]
  end

  def get_and_set(klass,parent_klass,parent_id,preserve_session=nil)
    klassname = klass.to_s.downcase
    sym = (klassname + '_id').to_sym
    id = params[sym] || session[sym]
    if id && id != '' && id.to_i != 0 # This latter in the case of "We don't know what the ID should be"
      # puts "get_and_set: found the id (#{id.inspect}) for #{klass.to_s} in either params (#{params[sym]}) or session (#{session[sym]})"
      # puts "get_and_set: what about string key? (#{params.inspect})"
      begin
        obj = klass.find(id)
      rescue ActiveRecord::RecordNotFound => e
        # If the object has just been deleted, the find can fail, so fall back to parent's first child
        id,obj = get_by_parent(klass,parent_klass,parent_id)
      end
    else
      id,obj = get_by_parent(klass,parent_klass,parent_id)
    end
    unless preserve_session
      logger.debug "Setting session[#{sym.to_s}] to #{id.to_s}"
      session[sym] = id
    end
    [id,obj]
  end

  # TODO: Delete this.
  def get_current_ids
    @user = current_user
    @user_id = current_user.id
    @group = current_user.groups.first
    @group_id = @group.id
    @farm = @group.farms.first
    @farm_id = @farm.id
  end

  def current_day
    # There will always be a field around with field ID 1
    session[:today] || today_or_latest(1)
  end

  def today_or_latest(field_id)
    field = Field.find(field_id)
    earliest = field.current_crop.emergence_date
    query = <<-END
      select max(date) as date from field_daily_weather where field_id=#{field_id}
    END
    latest = FieldDailyWeather.find_by_sql(query).first.date
    day = Date.today
    day = earliest if day < earliest
    day
  end

  def set_parent_id(attribs,params,parent_id_sym,parent_var)
    parent_id = attribs[parent_id_sym]
    if parent_id == nil || parent_id == '' || parent_id == '_empty'
      attribs[parent_id_sym] = params[:parent_id] == '' ? parent_var : params[:parent_id]
    end
  end

  # Check to see if any of our pivots need to be cloned.
  def check_pivots_for_cloning(clone_to = nil)
    clone_to ||= Time.now.year
    return unless @group
    if @farm
      farms = [@farm]
    else
      farms = @group.farms
    end
    # What needs cloning? Well, the latest set of pivots whose cropping years are < clone_to
    latest_pivots = Farm.latest_pivots(farms)
    latest_pivot_year = latest_pivots.first.cropping_year
    (latest_pivot_year < clone_to) ? latest_pivots : nil
  end
end
