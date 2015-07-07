require 'rails_helper'

describe Crop do
  let(:crop) { Crop.new }

  describe '#set_defaults' do
    describe '#plant' do
      context 'when the crop does not have a plant associated with it' do
        it 'associates the default plant' do
          expect { crop.valid? }.to change { crop.plant }.to Plant.default_plant
        end
      end

      context 'when the crop has a plant associated with it' do
        it 'does not change the plant' do
          crop.plant = Alfalfa.first
          expect { crop.valid? }.not_to change { crop.plant }
        end
      end
    end
  end
end
