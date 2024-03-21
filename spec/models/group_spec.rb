require "rails_helper"

describe Group do
  before do
    allow_any_instance_of(Field)
      .to receive(:date_endpoints)
      .and_return([Date.yesterday, Date.today])
  end

  let(:group) { build :group }
  let(:user) { build :user }

  describe "#create_dependent_objects" do
    it "is called after create" do
      expect(group).to receive(:create_dependent_objects)

      group.save
    end

    it "associates a farm with the group" do
      expect { group.save }.to change { group.farms.empty? }.to(false)
    end
  end

  describe "#destroy" do
    it "removes associated farms" do
      group.save!
      group.reload
      expect { group.destroy }.to change { Farm.count }
    end

    it "removes associated weather stations" do
      group.save!
      group.weather_stations << WeatherStation.new
      group.reload
      expect { group.destroy }.to change { WeatherStation.count }
    end

    it "removes associated memberships" do
      group.save!
      group.users << user
      group.reload
      expect { group.destroy }.to change { Membership.count }
    end
  end
end
