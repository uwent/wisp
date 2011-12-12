class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticationHelper
  
  def self.set_default_filters
    if AuthenticationHelper::USING_OPENID
      before_filter :ensure_signed_in, :except => :post_data # At least until I figure out how to get the grids to deal
    else
      before_filter :ensure_signed_in
    end
    before_filter :current_user, :get_current_ids
  end
  
  private
  def get_group
    unless @current_user
      return nil
    end
    @group = @current_user.groups.first
  end
  
  def get_and_set(klass,parent_klass,parent_id,preserve_session=nil)
    klassname = klass.to_s.downcase
    sym = (klassname + '_id').to_sym
    id = params[sym] || session[sym]
    if id
      # puts "get_and_set: found the id for #{klass.to_s} in either params (#{params[sym]}) or session (#{session[sym]})"
      # puts "get_and_set: what about string key? (#{params.inspect})"
      obj = klass.find(id)
    else
      plural = klass.to_s.downcase + 's'
      parent_obj = parent_klass.find(parent_id)
      obj = eval("parent_obj.#{plural}.first")
      id = obj[:id] if obj
    end
    unless preserve_session
      session[sym] = id
    end
    [id,obj]
  end
  
  def get_current_ids
    get_group
    unless @current_user
      logger.warn "get_current_ids: no user!"
      return 
    end
    unless @group
      logger.warn "get_current_ids: no group!"
      return
    end
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
    logger.info "group_id #{@group_id}, @current_user #{@current_user}, @farm_id #{@farm_id}, @field_id #{@field_id}"
  end
  
end
