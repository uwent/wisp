module ApplicationHelper
  def date_selectors(opts = {})
    @yesterday = 1.day.ago
    opts = opts_with_defaults opts, {names: %w[startyear startmonth startday], first_year: 2000, day: @yesterday.day, sep_str: " "}

    year_select = select_tag(opts[:names][0], options_for_select(opts[:first_year]..@yesterday.year, @yesterday.year))
    month_select = my_select_month(@yesterday, opts)
    day_select = select_tag(opts[:names][2], options_for_select(1..31, opts[:day]))
    "#{year_select}#{opts[:sep_str]}#{month_select}#{opts[:sep_str]}#{day_select}".html_safe
  end

  def coord_select_options(start = 42.0, finish = 50.0, step = 0.4)
    @coords = []
    start.step(finish, step) { |coord| @coords << coord }
    options_for_select @coords
  end

  def opts_with_defaults(opts, defaults)
    new_opts = {}
    defaults.keys.each { |defkey| new_opts[defkey] = opts[defkey] || defaults[defkey] }
    new_opts
  end

  def format_user_date(date, inline: false)
    date = date.to_date
    "#{date}#{inline ? ' ' : '<br>'}<span style='font-size:small'>(#{time_ago_in_words(date)} ago)</span>".html_safe
  rescue
    ""
  end

  private

  def my_select_month(date, opts)
    fix_month_fieldname(select_month(date, use_short_month: true), opts)
  end

  def fix_month_fieldname(str, opts)
    str.gsub("name=\"date[month]", "name=\"#{opts[:names][1]}")
  end

  def abr(date)
    if date
      date.strftime("%D")
    else
      ""
    end
  end

  def image_folder_path(folder)
    path = image_path(folder, skip_pipeline: true)
    path.gsub(/[^\d]\d+$/, "")
  end

  def merge_usuals(args)
    args.merge(
      user_id: @user[:id],
      group_id: @group[:id],
      farm_id: @farm[:id],
      pivot_id: @pivot[:id],
      field_id: @field[:id],
      crop_id: @crop[:id] || @field.crops.first[:id] # FIXME: Could this turn into a bug after the first season?
    )
    # puts "mu: user_id #{ret[:user_id]}, group_id #{ret[:group_id]}, farm_id #{ret[:farm_id]}, pivot_id #{ret[:pivot_id]}, field_id #{ret[:field_id]}, crop_id #{ret[:crop_id]}"
  end

  def url_with_usuals(args)
    # Going to try going without this one
    # url_for(merge_usuals(args))
    url_for(args)
  end

  def grid_data_url(what, parent_object)
    url_with_usuals controller: what.to_s, q: 1, parent_id: parent_object, user_id: @user_id
  end

  def grid_post_data_url(what, parent_object)
    url_with_usuals controller: what.to_s, action: :post_data, parent_id: parent_object
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

  def so_far(str, delimiter = ",")
    if str == ""
      str
    else
      str + delimiter
    end
  end

  # make COLUMN_NAMES available to Javascript
  def column_names_to_s(controller_class)
    "[" + controller_class::COLUMN_NAMES.inject("") { |str, col_sym| so_far(str) + "'#{col_sym}'" } + "]"
  end

  def energy_types_for_select
    [
      "Electric",
      "Diesel",
      "Gasoline",
      "LP Gas",
      "Natural Gas",
      "Pub. water system",
      "Other"
    ]
      .map(&:titleize)
      .map do |value|
      [value, value].join(":")
    end.join(";")
  end

  def soil_types_for_select
    # 1:Sandy Loam;2:Silt Loam
    soils = SoilType.all
    soils.inject("") { |str, soil_type| so_far(str, ";") + "#{soil_type[:id]}:#{soil_type.name}" }
  end

  def plant_types_for_select
    # 1:Potato;2:Snap Bean
    plants = Plant.all.sort_by(&:name)
    plants.inject("") { |str, plant| so_far(str, ";") + "#{plant[:id]}:#{plant.name}" }
  end

  def soil_characteristics
    SoilType.all.each_with_object({}) do |soil_type, memo|
      memo[soil_type.id.to_s] = {
        field_capacity_pct: number_with_precision(100 * soil_type[:field_capacity], precision: 1).to_s,
        perm_wilting_pt_pct: number_with_precision(100 * soil_type[:perm_wilting_pt], precision: 1).to_s
      }
    end.to_json.html_safe
  end

  # Helper method to enumerate all plant characteristics in JSON format, suitable for use in a grid
  # to fill in default values
  def plant_characteristics
    plants = Plant.all.sort_by(&:name)
    str = plants.inject("") do |str, plant|
      so_far(str) + plant[:id].to_s + ":" + "{default_max_root_zone_depth:" + (plant[:default_max_root_zone_depth]).to_s + "}"
    end
    "{#{str}}"
  end
end
