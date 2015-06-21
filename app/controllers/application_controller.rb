class ApplicationController < ActionController::Base
  protect_from_forgery

  # Implicit conversion of nil into string error with stylesheet tags and content_for, per
  # http://stackoverflow.com/questions/16044008/no-implicit-conversion-of-nil-into-string
  ActionController::Base.config.relative_url_root = ''

  def self.set_default_filters
    :ensure_signed_in
    :get_current_ids
  end

  def self.jsonify(hash)
    hash.inject({}) {|ret,entry| ret.merge({entry[0].to_s => entry[1].to_s})}
  end
  
  private
  def get_group
    unless @user
      return nil
    end
    @group = @user.groups.first
  end

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
  
  def get_current_ids
    # Should we really be allowing user id in a param? Shouldn't it live in the session and be controlled only by
    # the login stuff?
    @user_id = params[:user_id] || session[:user_id]
    @user = User.find(@user_id)
    @group_id,@group = get_and_set(Group,User,@user_id)
  end
  
  # Filter method to flag errors and redirect when we need a group to be present
  def ensure_group
    unless @group
      flash[:notice] = 'Sorry, a login error has occurred'
      logger.error 'Error: method called, but no group was available '+params.inspect+'; session '+session.inspect
      redirect_to :controller => :wisp
    end
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
  
  # debugging
  def log_current_ids
    logger.info "group_id #{@group_id}, @user #{@user}, @farm_id #{@farm_id}, @field_id #{@field_id}"
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
