module ApplicationHelper
  def date_selectors(opts={})
    @yesterday = 1.day.ago
    opts = opts_with_defaults opts, {:names => %w(startyear startmonth startday), :first_year => 2000, :day => @yesterday.day, :sep_str => " "}
    
    year_select =  select_tag(opts[:names][0], options_for_select(opts[:first_year]..@yesterday.year, @yesterday.year))
    month_select = my_select_month(@yesterday,opts)
    day_select = select_tag(opts[:names][2], options_for_select(1..31, opts[:day]))
    "#{year_select}#{opts[:sep_str]}#{month_select}#{opts[:sep_str]}#{day_select}".html_safe
  end
  
  def coord_select_options(start=42.0,finish=50.0,step=0.4)
    @coords = []; (start).step(finish,step) {|coord| @coords << coord }
    options_for_select @coords
  end
  
  def opts_with_defaults(opts,defaults)
    new_opts={}
    defaults.keys.each {|defkey| new_opts[defkey] = opts[defkey] || defaults[defkey]}
    new_opts
  end

  private
  
  def my_select_month(date,opts)
    fix_month_fieldname(select_month(date,:use_short_month => true),opts)
  end
  
  def fix_month_fieldname(str,opts)
    str.gsub("name=\"date[month]","name=\"#{opts[:names][1]}")
  end
  
  def abr(date)
    if date
      date.strftime('%D')
    else
      ""
    end
  end
  
  def image_folder_path(folder)
    path = image_path(folder)
    path.gsub(/[^\d][\d]+$/,'')
  end
  
  def merge_usuals(args)
    ret = args.merge(
      :user_id => @user[:id],
      :group_id => @group[:id],
      :farm_id => @farm[:id],
      :pivot_id => @pivot[:id],
      :field_id => @field[:id],
      :crop_id => @crop[:id] || @field.crops.first[:id] # FIXME: Could this turn into a bug after the first season?
      )
    puts "mu: user_id #{ret[:user_id]}, group_id #{ret[:group_id]}, farm_id #{ret[:farm_id]}, pivot_id #{ret[:pivot_id]}, field_id #{ret[:field_id]}, crop_id #{ret[:crop_id]}"
    ret
  end
  
  def url_with_usuals(args)
    # Going to try going without this one
    # url_for(merge_usuals(args))
    url_for(args)
  end
  
  def grid_data_url(what,parent_object)
    url_with_usuals :controller => what.to_s, :q => 1, :parent_id => parent_object, :user_id => @user_id
  end
  
  def grid_post_data_url(what,parent_object)
    url_with_usuals :controller => what.to_s, :action  => :post_data, :parent_id => parent_object
  end
  
  def grid_javascript_settings
    ret = "\n// State variables:"
    ret += "\nvar user_id = #{@user_id};" if @user_id
    ret += "\nvar group_id = #{@group_id};" if @group_id
    ret += "\nvar farm_id = #{@farm_id};" if @farm_id
    ret += "\nvar pivot_id = #{@pivot_id};" if @pivot_id
    ret += "\nvar field_id = #{@field_id};" if @field_id
    ret += "\nvar crop_id = #{@crop_id};" if @crop_id
    ret
  end
  
  def so_far(str,delimiter=',')
    if str == ''
      str
    else
      str + delimiter
    end
  end
  
  # make COLUMN_NAMES available to Javascript
  def column_names_to_s(controller_class)
    '[' + controller_class::COLUMN_NAMES.inject("") {|str,col_sym| so_far(str) + "'#{col_sym.to_s}'"} + ']'
  end
  
  def soil_types_for_select
    # 1:Percent Cover;2:Leaf Area Index
    soils = SoilType.all
    soils.inject("") {|str,soil_type| so_far(str,';') + "#{soil_type[:id]}:#{soil_type.name}"}
  end
  
  def soil_characteristics
    soils = SoilType.all
    str = soils.inject("") do |str,soil_type|
      so_far(str) + 
        soil_type[:id].to_s + ':' + 
        '{field_capacity_pct:' + (100*soil_type[:field_capacity]).to_s + ',' +
         'perm_wilting_pt_pct:' + (100*soil_type[:perm_wilting_pt]).to_s + '}'
    end
    "{#{str}}"
  end
end
