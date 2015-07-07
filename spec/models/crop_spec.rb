require 'rails_helper'

describe Crop do
  let(:crop) { Crop.new }

  describe '#set_defaults' do
    context 'when the crop is new' do
      let(:crop) { Crop.new }

      context 'and a plant is associated with it' do
        let(:crop) { build :crop, plant: Alfalfa.first }

        it 'does not change the plant' do
          expect { crop.valid? }.not_to change { crop.plant }
        end
      end

      context 'and a plant is not associated with it' do
        it 'changes the plant' do
          expect { crop.valid? }.to change { crop.plant }.to(Plant.default_plant)
        end
      end

      context 'and variety is set' do
        let(:crop) { build :crop, variety: 'Some variety' }

        it 'does not change the variety' do
          expect { crop.valid? }.not_to change { crop.variety }
        end
      end

      context 'and variety is not set' do
        let(:crop) { build :crop, variety: nil }

        it 'changes the variety' do
          expect { crop.valid? }.to change { crop.variety }.to('A variety')
        end
      end
    end

    context 'when the crop is not new' do
      let(:crop) { create :crop }
    end
  end
end
