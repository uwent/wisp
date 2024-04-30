require "rails_helper"

describe Farm do
  before do
    allow_any_instance_of(Field)
      .to receive(:date_endpoints)
      .and_return([Date.yesterday, Date.today])
  end

  let(:group) { build :group }
  let(:farm) { build :farm, year: Date.current.year}

  describe "#validation" do
    it "can create valid farm" do
      expect(farm).to be_valid
    end

    it "is not valid without a year" do
      farm.year = nil
      expect(farm).not_to be_valid
    end
  end

  describe "#create_dependent_objects" do
    it "is called after create" do
      expect(farm).to receive(:create_dependent_objects)
      farm.save!
    end

    it "associates a pivot with the farm" do
      expect { farm.save! }.to change { farm.pivots.empty? }.to(false)
    end
  end

  describe "#destroy" do
    it "removes associated pivots" do
      farm.save!
      farm.reload
      expect { farm.destroy! }.to change { Pivot.count }
    end
  end

  describe "#latest_pivots" do
    it "should return all pivots in the most recent year" do
      farm.save!
      expect(Farm.latest_pivots([farm])).to eq farm.pivots
    end
  end

  describe "#my_farms" do
    it "should be this farms's group's farms" do
      group.save!
      farm = group.farms.first
      expect(group.farms.size).to eq 1
      expect(Farm.my_farms(farm.group_id)).to eq group.farms
    end
  end
end
