require "rails_helper"

describe Crop do
  let(:crop) { Crop.new }

  describe "validation on create" do
    before { allow_any_instance_of(Field).to receive(:update_with_emergence_date) }

    context "when the crop is new" do
      let(:crop) { Crop.new }

      context "and a plant is associated with it" do
        let(:crop) { build :crop, plant: Alfalfa.first }

        it "does not change the plant" do
          expect { crop.valid? }.not_to change { crop.plant }
        end
      end

      context "and a plant is not associated with it" do
        it "changes the plant" do
          expect { crop.valid? }.to change { crop.plant }.to(Plant.default_plant)
        end
      end

      context "and a max_root_zone_depth is set" do
        let(:crop) { build :crop, max_root_zone_depth: Plant.default_plant.default_max_root_zone_depth * 2 }

        it "does not change the max_root_zone_depth" do
          expect { crop.valid? }.not_to change { crop.max_root_zone_depth }
        end
      end

      context "and a max_root_zone_depth is not set" do
        let(:crop) { build :crop, plant: nil, max_root_zone_depth: nil }

        it "sets the max_root_zone_depth to the plant default max_root_zone_depth" do
          expect { crop.valid? }.to change { crop.max_root_zone_depth }.to(Plant.default_plant.default_max_root_zone_depth)
        end
      end

      context "and name is set" do
        let(:crop) { build :crop, name: "Some name" }

        it "does not change the name" do
          expect { crop.valid? }.not_to change { crop.name }
        end
      end

      context "and name is not set" do
        let(:field) { create :field, id: 123 }
        let(:crop) { build :crop, field: field, name: nil }

        it "changes the name" do
          expect { crop.valid? }.to change { crop.name }.to("New crop")
        end
      end

      context "and variety is set" do
        let(:crop) { build :crop, variety: "Some variety" }

        it "does not change the variety" do
          expect { crop.valid? }.not_to change { crop.variety }
        end
      end

      context "and variety is not set" do
        let(:crop) { build :crop, variety: nil }

        it "changes the variety" do
          expect { crop.valid? }.to change { crop.variety }.to("A variety")
        end
      end
    end

    context "when the crop is not new" do
      let(:crop) { create :crop }

      it "does not set defaults" do
        crop.variety = nil

        expect { crop.valid? }.not_to change { crop.variety }
      end
    end
  end

  describe "new year" do
    let(:crop) {
      create :crop, emergence_date: 2.days.ago,
        harvest_or_kill_date: 1.day.ago
    }

    it "sets emergence date to default" do
      crop.new_year
      crop.reload
      expect(crop.emergence_date).to eq Date.civil(Time.now.year, *Field::EMERGENCE_DATE)
    end

    it "should empty kill/harvest date" do
      crop.new_year
      crop.reload
      expect(crop.harvest_or_kill_date).to be_nil
    end
  end

  describe "updating field with emergence date" do
    let(:crop) { create :crop, emergence_date: 2.days.ago }

    context "when an attribute that triggers a field update has changed" do
      let(:new_emergence_date) { crop.emergence_date += 1.day }

      it "sends :update_with_emergence_date to the field with the emergence date" do
        crop.emergence_date = new_emergence_date

        expect(crop.field).to receive(:update_with_emergence_date).with(new_emergence_date)

        crop.save
      end
    end

    context "when no attributes that trigger a field update have changed" do
      it "does not send :update_with_emergence_date to the field" do
        crop.name = "#{crop.name} - changed"

        expect(crop.field).not_to receive(:update_with_emergence_date)

        crop.save
      end
    end
  end

  describe "#act" do
    it "is an empty string" do
      expect(crop.act).to eq("")
    end
  end
end
