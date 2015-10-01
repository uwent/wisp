require 'rails_helper'

describe Field do
  describe '#target_ad_pct' do
    it { is_expected.to have_valid(:target_ad_pct).when nil, 1.0, 49.3, 100.0 }
    it { is_expected.not_to have_valid(:target_ad_pct).when 0, 0.99, 100.01 }
  end

  describe '#et_method' do
    it { is_expected.to have_valid(:et_method).when Field::PCT_COVER_METHOD, Field::LAI_METHOD }
    it { is_expected.not_to have_valid(:et_method).when 3 }
  end

  describe '.starts_on' do
    let(:year) { 2015 }

    it 'is 2015-04-01' do
      expect(Field.starts_on(2015)).to eq(Date.parse('2015-04-01'))
    end
  end

  describe '.ends_on' do
    let(:year) { 2015 }

    it 'is 2015-11-30' do
      expect(Field.ends_on(2015)).to eq(Date.parse('2015-11-30'))
    end
  end

  describe '.emerges_on' do
    let(:year) { 2015 }

    it 'is 2015-05-01' do
      expect(Field.emerges_on(2015)).to eq(Date.parse('2015-05-01'))
    end
  end

  describe '#et_method_name' do
    let(:field) { build :field, et_method: et_method }

    context 'when the et_method is PCT_COVER_METHOD' do
      let(:et_method) { Field::PCT_COVER_METHOD }

      it 'is Pct Cover' do
        expect(field.et_method_name).to eq 'Pct Cover'
      end
    end

    context 'when the et_method is LAI_METHOD' do
      let(:et_method) { Field::LAI_METHOD }

      it 'is LAI' do
        expect(field.et_method_name).to eq 'LAI'
      end
    end
  end

  describe '#adj_et' do
    let(:et_method) { nil }
    let(:field) { create :field, et_method: et_method }
    let(:field_daily_weather) do
      build :field_daily_weather, ref_et: ref_et, leaf_area_index: leaf_area_index
    end
    let(:ref_et) { nil }
    let(:pct_cover) { nil }
    let(:leaf_area_index) { nil }

    let(:crop_mock) { double('Crop') }
    let(:plant_mock) { double('Plant') }

    before do
      expect(field).to receive(:current_crop).at_least(1).times.and_return crop_mock
    end

    context 'when there is a current crop' do
      before do
        allow(crop_mock).to receive(:plant).and_return plant_mock
      end

      context 'and field daily weather has ref_et' do
        let(:ref_et) { 0 }

        context 'and the et_method is PCT_COVER' do
          let(:et_method) { Field::PCT_COVER_METHOD }

          before do
            allow(field_daily_weather).to receive(:pct_cover).and_return(pct_cover)
          end

          context 'and the field daily weather has pct_cover' do
            let(:pct_cover) { 0 }

            it 'returns plant.calc_ad_et_pct_cover' do
              expect(plant_mock).to receive(:calc_adj_et_pct_cover).with(ref_et, pct_cover).and_return 'pct cover result'

              field.adj_et(field_daily_weather)
            end
          end

          context 'and the field daily weather does not have pct_cover' do
            it 'is nil' do
              expect(field.adj_et(field_daily_weather)).to be_nil
            end
          end
        end

        context 'and the et_method is LAI_METHOD' do
          let(:et_method) { Field::LAI_METHOD }

          context 'and the field daily weather has leaf_area_index' do
            let(:leaf_area_index) { 0 }

            it 'returns plant.calc_ad_et_lai' do
              expect(plant_mock).to receive(:calc_adj_et_lai).with(ref_et, leaf_area_index).and_return 'lai result'

              field.adj_et(field_daily_weather)
            end
          end

          context 'and the field daily weather does not have leaf_area_index' do
            it 'is nil' do
              expect(field.adj_et(field_daily_weather)).to be_nil
            end
          end
        end
      end
    end

    context 'when there is not a current crop' do
      let(:crop_mock) { nil }

      it 'is nil' do
        expect(field.adj_et(field_daily_weather)).to be_nil
      end
    end
  end

  describe '#year' do
    let(:field) { build :field }
    let(:pivot_farm) { nil }

    before { allow(field).to receive(:pivot_farm).and_return pivot_farm }

    context 'when there is a farm via the pivot' do
      let(:pivot_farm) { build :farm, year: 1999 }

      it 'is the farm year' do
        expect(field.year).to eq(1999)
      end
    end

    context 'when there is not a farm via the pivot' do
      it 'is the current year' do
        expect(field.year).to eq(Time.now.year)
      end
    end
  end

  describe '#field_capacity' do
    let(:field) { build :field, soil_type: soil_type, field_capacity: field_capacity }
    let(:soil_type) { build :soil_type, field_capacity: 0.2 }

    context 'when field_capacity is set' do
      context 'but it is zero' do
        let(:field_capacity) { 0.0 }

        context 'and it has a soil type' do
          it 'is the soil type field capacity' do
            expect(field.field_capacity).to eq(0.2)
          end
        end

        context 'and it does not have a soil type' do
          let(:soil_type) { nil }

          it 'is the default field capacity' do
            expect(field.field_capacity).to eq(0.31)
          end
        end
      end

      context 'and it is not zero' do
        let(:field_capacity) { 0.1 }

        it 'is the field capacity' do
          expect(field.field_capacity).to eq(0.1)
        end
      end
    end

    context 'when field capacity is not set' do
      let(:field_capacity) { nil }

      context 'and it has a soil type' do
        it 'is the soil type field capacity' do
          expect(field.field_capacity).to eq(0.2)
        end
      end

      context 'and it does not have a soil type' do
        let(:soil_type) { nil }

        it 'is the default field capacity' do
          expect(field.field_capacity).to eq(0.31)
        end
      end
    end
  end

  describe '#field_capacity_pct=' do
    let(:field) { build :field }

    it 'stores the percentage' do
      field.field_capacity_pct = 101.0
      expect(field.field_capacity).to eq(1.01)
    end
  end

  describe '#field_capacity_pct' do
    let(:field) { build :field, field_capacity: 1.01 }

    it 'is the percentage' do
      expect(field.field_capacity_pct).to eq(101.0)
    end
  end
end
