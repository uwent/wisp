require 'test_helper'

class CropTest < ActiveSupport::TestCase
  test "implements Owned#owner" do
    crop = Crop.first
    assert_nothing_raised(NotImplementedError) { crop.owner }
  end

  test "implements Owned#auth" do
    crop = Crop.first
    actor = crop.field.pivot.farm.group
    assert(crop.auth(actor,nil), "Could not perform action for #{actor.description}")
  end
end
