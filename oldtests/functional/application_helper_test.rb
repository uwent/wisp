require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  def test_date_selector_existence
    assert(date_selectors, "Should have been able to call date_selectors helper method!")
  end

  def test_soil_characteristics
    # puts soil_characteristics
  end
end
