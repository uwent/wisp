class WeatherStationData < ApplicationRecord
  belongs_to :weather_station
  before_save :send_changes

  def self.for_date(date)
    where(date: date)
  end

  def empty?
    attributes
      .except("id", "date", "weather_station_id", "updated_at", "created_at")
      .values
      .none?(&:present?)
  end

  # only copy the following to the corresponding fdw
  COLUMNS_TO_PROPAGATE = [
    :entered_pct_cover,
    :entered_pct_moisture,
    :irrigation,
    :rain,
    :ref_et
  ]

  # don't bother propagating (and triggering cascading balance calcs for) changes smaller than:
  CHANGE_EPSILON = 0.00001

  # Here's the deal: ActiveRecord gives us a "changes" hash where column names (as strings)
  # point to an array of [old_value,new_value]. So we go through our list of significant cols
  # COLUMNS_TO_PROPAGATE; if any of them show up in the changes, we assess if the new value is nil
  # (if so, don't bother proceeding), if the old value was nil (if so, proceed regardless), and
  # if the values differ by more than CHANGE_EPSILON.

  # returns [old_value,new_value] or nil
  def extract_changes(col_sym)
    return nil unless (change = changes[col_sym.to_s])
    [change[0], change[1]]
  end

  def send_changes
    changes_to_send = COLUMNS_TO_PROPAGATE.each_with_object({}) do |col, hash|
      old_value, new_value = extract_changes(col)
      if new_value
        if old_value.nil? || (old_value.to_f - new_value.to_f) > CHANGE_EPSILON
          hash.merge!({col => new_value.to_f})
        end
      end
    end
    weather_station.wx_record_saved(changes_to_send.merge({date: date})) unless changes_to_send == {}
  end

  # Set our (non-persisted) attribute @multi_edit_changes to list all the cols that have significant updates,
  # because we only want to propagate changes to the field daily weather. For example, if someone
  # edits the rainfall for a given date, then later comes back and edits the irrigation, we don't
  # want to propagate both values, because in the interim the user might have hand-entered a rainfall
  # value for a particular field for that date. In other words: Only transmit a value
  # to all the fields once.
  def flag_changes(attribs)
    @multi_edit_changes = []
    COLUMNS_TO_PROPAGATE.each do |col|
      val = attribs[col]
      # We don't use multi-edit to nil out values; skip if new value for col is nil
      if !val.nil?
        # Real value overwriting nil, yep that's a change
        if self[col].nil?
          @multi_edit_changes << col
        elsif (self[col] - val).abs > CHANGE_EPSILON
          @multi_edit_changes << col
        end
      end
    end
  end
end
