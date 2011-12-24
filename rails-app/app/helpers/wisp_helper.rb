module WispHelper
  def options_from_group_for_select(group,selected_farm)
    arr = group.farms.map { |farm|  [farm.name,farm.id]}
    ret = options_for_select(arr,selected_farm[:id])
  end
  def options_from_farm_for_select(farm,selected_pivot)
    arr = farm.pivots.map { |pivot|  [pivot.name,pivot.id]}
    ret = options_for_select(arr,selected_pivot[:id])
  end
  def options_from_pivot_for_select(pivot,selected_field)
    arr = pivot.fields.map { |field|  [field.name,field.id]}
    ret = options_for_select(arr,selected_field[:id])
  end
end
