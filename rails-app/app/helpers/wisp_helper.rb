module WispHelper
  def options_from_pivot_for_select(pivot,selected_field)
    arr = pivot.fields.map { |field|  [field.name,field.id]}
    ret = options_for_select(arr,selected_field[:id])
  end
end
