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
    let(:field) { build :field, et_method: et_method }
    let(:field_daily_weather) do
      build :field_daily_weather, ref_et: ref_et, leaf_area_index: leaf_area_index
    end
    let(:ref_et) { nil }
    let(:pct_cover) { nil }
    let(:leaf_area_index) { nil }

    let(:crop_mock) { instance_double('Crop') }
    let(:plant_mock) { instance_double('Plant') }

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
          it 'is the soil type value' do
            expect(field.field_capacity).to eq(0.2)
          end
        end

        context 'and it does not have a soil type' do
          let(:soil_type) { nil }

          it 'is the default value' do
            expect(field.field_capacity).to eq(0.31)
          end
        end
      end

      context 'and it is not zero' do
        let(:field_capacity) { 0.1 }

        it 'is the field value' do
          expect(field.field_capacity).to eq(0.1)
        end
      end
    end

    context 'when field_capacity is not set' do
      let(:field_capacity) { nil }

      context 'and it has a soil type' do
        it 'is the soil type value' do
          expect(field.field_capacity).to eq(0.2)
        end
      end

      context 'and it does not have a soil type' do
        let(:soil_type) { nil }

        it 'is the default value' do
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

  describe 'perm_wilting_pt' do
    let(:field) { build :field, soil_type: soil_type, perm_wilting_pt: perm_wilting_pt }
    let(:soil_type) { build :soil_type, perm_wilting_pt: 0.2 }

    context 'when perm_wilting_pt is set' do
      context 'but it is zero' do
        let(:perm_wilting_pt) { 0.0 }

        context 'and it has a soil type' do
          it 'is the soil type value' do
            expect(field.perm_wilting_pt).to eq(0.2)
          end
        end

        context 'and it does not have a soil type' do
          let(:soil_type) { nil }

          it 'is the default field value' do
            expect(field.perm_wilting_pt).to eq(0.14)
          end
        end
      end

      context 'and it is not zero' do
        let(:perm_wilting_pt) { 0.1 }

        it 'is the field value' do
          expect(field.perm_wilting_pt).to eq(0.1)
        end
      end
    end

    context 'when perm_wilting_pt is not set' do
      let(:perm_wilting_pt) { nil }

      context 'and it has a soil type' do
        it 'is the soil type value' do
          expect(field.perm_wilting_pt).to eq(0.2)
        end
      end

      context 'and it does not have a soil type' do
        let(:soil_type) { nil }

        it 'is the default value' do
          expect(field.perm_wilting_pt).to eq(0.14)
        end
      end
    end
  end

  describe '#perm_wilting_pt_pct=' do
    let(:field) { build :field }

    it 'stores the percentage' do
      field.perm_wilting_pt_pct= 101.0
      expect(field.perm_wilting_pt).to eq(1.01)
    end
  end

  describe '#perm_wilting_pt_pct' do
    let(:field) { build :field, perm_wilting_pt: 1.01 }

    it 'is the percentage' do
      expect(field.perm_wilting_pt_pct).to eq(101.0)
    end
  end

  describe '#create_dependent_objects' do
    let(:field ) { Field.new(et_method: et_method) }
    let(:et_method) { nil }

    it 'is called after create' do
      expect(field).to receive(:create_dependent_objects)

      field.save
    end

    it 'associates a crop with the field' do
      expect { field.save }.to change { field.current_crop.present? }.to(true)
    end

    it 'creates field daily weather records' do
      expect { field.save }.to change { field.field_daily_weather.any? }.to(true)
    end

    context 'when the et_method is LAI_METHOD' do
      let(:et_method) { Field::LAI_METHOD }

      it 'sets calculated_pct_cover to nil for all the records' do
        field.save

        expect(field.field_daily_weather.pluck(:calculated_pct_cover).uniq).to eq([nil])
      end

      it 'sets leaf_area_index to something for some of the records' do
        field.save

        expect(field.field_daily_weather.pluck(:leaf_area_index).uniq.any?).to be(true)
      end
    end

    context 'when the et_method is PCT_COVER_METHOD' do
      let(:et_method) { Field::PCT_COVER_METHOD }

      it 'sets calculated_pct_cover to 0.0 for all the records' do
        field.save

        expect(field.field_daily_weather.pluck(:calculated_pct_cover).uniq).to eq([0.0])
      end

      it 'sets leaf_area_index to nil for all the records' do
        field.save

        expect(field.field_daily_weather.pluck(:leaf_area_index).uniq).to eq([nil])
      end
    end
  end

  describe '#initial_ad' do
    context 'when the preconditions are satisfied' do
      let(:field) { create :field }
      let(:delta) { 2 ** -20 }

      it 'is 0.8' do
        expect(field.initial_ad).to be_within(delta).of(0.8)
      end
    end

    context 'when the preconditions are not satisfied' do
      let(:field) { build :field }

      it 'is the default value' do
        expect(field.initial_ad).to eq(-999.0)
      end
    end
  end

  describe '#update_canopy' do
    context 'when the et_method is LAI_METHOD' do

    end

    context 'when the et_method is PCT_COVER_METHOD' do

    end
  end

  describe '#destroy' do
    before do
      allow_any_instance_of(Field)
        .to receive(:date_endpoints)
        .and_return([Date.yesterday, Date.today])
    end
    let (:field) { create :field }

    it 'should remove crops' do
      field.reload
      field.crops  << create(:crop)
      expect { field.destroy! }.to change { Crop.count }
    end

    it 'should remove multi_edit_groups' do
      field.reload
      field.weather_stations << create(:weather_station)
      expect { field.destroy! }.to change { MultiEditLink.count }
    end

    it 'should remove field_daily_weather' do
      field.reload
      expect { field.destroy! }.to change { FieldDailyWeather.count }
    end
  end
end
