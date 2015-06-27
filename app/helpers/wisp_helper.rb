module WispHelper
  def options_from_group_for_select(group,selected_farm)
    arr = group.farms.map { |farm|  [truncate(farm.name,length: 40),farm.id]}
    ret = options_for_select(arr,selected_farm[:id])
  end

  def options_from_farm_for_select(farm,selected_pivot)
    arr = farm.pivots.map { |pivot|  [truncate(pivot.name,length: 40),pivot.id]}
    ret = options_for_select(arr,selected_pivot[:id])
  end

  def options_from_pivot_for_select(pivot,selected_field)
    arr = pivot.fields.map { |field|  [truncate(field.name,length: 40),field.id]}
    ret = options_for_select(arr,selected_field[:id])
  end

  def problems(group)
    # Hmm. Want a hierarchy of collections matching the criterion here,
    # but unsure how to compose it. Hash of hashes? Array of Arrays? Need
    # some properties (name and id) as well as children for all but leaf level.
  end

  # Per https://github.com/plataformatec/devise/wiki/How-To:-Display-a-custom-sign_in-form-anywhere-in-your-app
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

end
