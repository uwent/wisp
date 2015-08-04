require 'rails_helper'

describe Plant do
  before { Plant.seed }

  describe '.default_plant' do
    it 'is Potato' do
      expect(Plant.default_plant.name).to eq('Potato')
    end
  end

  describe '.seed' do
    context 'when the seeded plants exist' do
      before { Plant.seed }

      it 'does not create new plants' do
        expect { Plant.seed }.not_to change { Plant.count }
      end
    end

    context 'when there are no plants' do
      before { Plant.destroy_all }

      it 'creates the initial plants' do
        expect { Plant.seed }.to change { Plant.count }.from(0).to(27)
      end
    end
  end

  describe '#lai_for' do
    context 'when the plant is Sweet Corn' do
      let(:plant) { SweetCorn.first }
      let(:days_since_emergence) { 14 }
      # TODO: Figure out what 'fdw' is and use a realistic value
      let(:fdw) { nil }

      it 'returns the result of sending fdw to lai_thermal' do
        expect(plant).to receive(:lai_thermal).with(fdw).and_return 'lai_thermal'

        expect(plant.lai_for(days_since_emergence, fdw)).to eq 'lai_thermal'
      end
    end

    # TODO: Use Plant.where.not(name: 'Sweet Corn')
    Plant.where('name != ?', 'Sweet Corn').each do |plant|
      context "when the plant is #{plant.class.name}" do
        let(:days_since_emergence) { 14 }
        let(:fdw) { nil }

        it 'returns the result of sending days_since_emergence to lai_corn' do
          expect(plant).to receive(:lai_corn).with(days_since_emergence).and_return 'lai_corn'

          expect(plant.lai_for(days_since_emergence, fdw)).to eq 'lai_corn'
        end
      end
    end
  end

  describe '#uses_degree_days?' do
    context 'when the plant is Sweet Corn' do
      let(:plant) { SweetCorn.first }

      context 'and the et method is LAI' do
        let(:et_method) { Field::LAI_METHOD }

        it 'is truthy' do
          expect(plant.uses_degree_days?(et_method)).to be_truthy
        end
      end

      context 'and the et method is PCT_COVER' do
        let(:et_method) { Field::PCT_COVER_METHOD }

        it 'is falsey' do
          expect(plant.uses_degree_days?(et_method)).to be_falsey
        end
      end
    end

    # TODO: Use Plant.where.not(name: 'Sweet Corn')
    Plant.where('name != ?', 'Sweet Corn').each do |plant|
      context "when the plant is #{plant.class.name}" do
        context 'and the et method is LAI' do
          let(:et_method) { Field::LAI_METHOD }

          it 'is falsey' do
            expect(plant.uses_degree_days?(et_method)).to be_falsey
          end
        end

        context 'and the et method is PCT_COVER' do
          let(:et_method) { Field::PCT_COVER_METHOD }

          it 'is falsey' do
            expect(plant.uses_degree_days?(et_method)).to be_falsey
          end
        end
      end
    end
  end

  describe '#calc_adj_et_lai_for_clumping' do
    let(:plant) { Plant.all.first } # TODO: shuffle
    let(:ref_et) { 'ref_et' }
    let(:lai) { 'lai' }

    it 'returns the result of sending the inputs to adj_et_lai_for_clumping' do
      expect(plant).to receive(:adj_et_lai_for_clumping).with(ref_et, lai).and_return 'adj_et_lai_for_clumping'

      expect(plant.calc_adj_et_lai_for_clumping(ref_et, lai)).to eq 'adj_et_lai_for_clumping'
    end
  end

  describe '#calc_adj_et_lai_for_nonclumping' do
    let(:plant) { Plant.all.first } # TODO: shuffle
    let(:ref_et) { 'ref_et' }
    let(:lai) { 'lai' }

    it 'returns the result of sending the inputs to adj_et_lai_for_nonclumping' do
      expect(plant).to receive(:adj_et_lai_for_nonclumping).with(ref_et, lai).and_return 'adj_et_lai_for_nonclumping'

      expect(plant.calc_adj_et_lai_for_nonclumping(ref_et, lai)).to eq 'adj_et_lai_for_nonclumping'
    end
  end

  describe '#calc_adj_et_lai' do
    let(:plant) { Plant.all.first } # TODO: shuffle
    let(:ref_et) { 'ref_et' }
    let(:lai) { 'lai' }

    it 'returns the result of sending the inputs to adj_et_lai_for_nonclumping' do
      expect(plant).to receive(:adj_et_lai_for_nonclumping).with(ref_et, lai).and_return 'adj_et_lai_for_nonclumping'

      expect(plant.calc_adj_et_lai(ref_et, lai)).to eq 'adj_et_lai_for_nonclumping'
    end
  end

  describe '#calc_adj_et_pct_cover' do
    let(:plant) { Plant.all.first } # TODO: shuffle
    let(:ref_et) { 'ref_et' }
    let(:pct_cover) { 'pct_cover' }

    it 'returns the result of sending the inputs to adj_et_pct_cover' do
      expect(plant).to receive(:adj_et_pct_cover).with(ref_et, pct_cover).and_return 'adj_et_pct_cover'

      expect(plant.calc_adj_et_pct_cover(ref_et, pct_cover)).to eq 'adj_et_pct_cover'
    end
  end
end
