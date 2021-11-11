require "rails_helper"

describe SoilType do
  describe ".default_soil_type" do
    it "is Sandy Loam" do
      expect(SoilType.default_soil_type.name).to eq "Sandy Loam"
    end
  end

  describe ".seed" do
    context "when the seeded soil types exist" do
      before { SoilType.seed }

      it "does not create new soil types" do
        expect { SoilType.seed }.not_to change { SoilType.count }
      end
    end

    context "when there are no soil types" do
      before { SoilType.destroy_all }

      it "creates the initial soil types" do
        expect { SoilType.seed }.to change { SoilType.count }.from(0).to(7)
      end
    end
  end
end
