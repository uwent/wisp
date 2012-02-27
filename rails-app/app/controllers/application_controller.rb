class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticationHelper
  
  def self.set_default_filters
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
      session[sym] = id
    end
    [id,obj]
  end
  
  def get_current_ids
    @user_id = params[:user_id] || session[:user_id]
    @user = User.find(@user_id)
    @group = @user.groups.first # someday this might change if we let users belong to > 1 groups
    # puts "get_current_ids: before get_and_set, @farm is #{@farm ? @farm.name : "Not set"}"
    @farm_id,@farm = get_and_set(Farm,Group,@group[:id],params[:preserve_farm]); return unless @farm_id
    # puts "get_current_ids: @farm is #{@farm.name}"
  	@pivot_id,@pivot = get_and_set(Pivot,Farm,@farm_id); return unless @pivot_id
  	@field_id,@field = get_and_set(Field,Pivot,@pivot_id); return unless @field_id
    @crop_id,@crop = get_and_set(Crop,Field,@field_id)
  end
  
  def current_day
    # There will always be a field around with field ID 1
    session[:today] || today_or_latest(1)
  end
  
  def today_or_latest(field_id)
    query = <<-END
      select max(date) as date from field_daily_weather where field_id=#{field_id}
    END
    latest = FieldDailyWeather.find_by_sql(query).first.date
    today = Date.today
    unless latest
      return today
    end
    if today > latest
      return latest
    else
      return today
    end
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
  
end
