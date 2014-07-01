# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
RailsApp::Application.initialize!

# Monkey-patch the method from the 2dc_jqgrid plugin. Rails has a javascript escaping method that
# inserts backslashes before single quotes; JQGrid chokes on that char sequence.
module JqgridJson
  alias :orig_to_jqgrid_json :to_jqgrid_json

  def to_jqgrid_json(attributes, current_page, per_page, total)
    orig_to_jqgrid_json(attributes, current_page, per_page, total).gsub("\\\'","'")
  end
end
