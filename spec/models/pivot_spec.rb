require "rails_helper"

describe Pivot do
  before do
    allow_any_instance_of(Field)
      .to receive(:date_endpoints)
      .and_return([Date.yesterday, Date.today])
    @group = Group.create
  end

  let(:pivot) { create :pivot }

  describe "#after_create" do
    let(:pivot) { build :pivot }
    it "creates a field" do
      expect { pivot.save }.to change { pivot.fields.count }.by(1)
    end
  end

  describe "#act" do
    it "is an empty string" do
      expect(pivot.act).to eq("")
    end
  end

  # describe '#clone_for' do
  #   let(:next_year) { Time.now.year + 1 }
  #   let(:new_pivot) { pivot.clone_for(next_year) }

  #   it 'returns a Pivot with the specified cropping year' do
  #     year = Time.now.year + 3
  #     expect(pivot.clone_for(year).cropping_year).to eq(year)
  #   end

  #   it 'returns a Pivot with the same attributes' do
  #     expect(new_pivot.attributes.except(*%w(id cropping_year created_at updated_at))).to \
  #       match(pivot.attributes.except(*%w(id cropping_year created_at updated_at)))
  #   end

  #   context 'when the pivot has multiple fields' do
  #     before do
  #       5.times do |n|
  #         pivot.fields.create(name: "Field #{n}")
  #       end
  #     end

  #     it 'returns a Pivot with the same number of fields' do
  #       expect(pivot.fields.count).to eq(new_pivot.fields.count)
  #     end

  #     it 'returns a Pivot with the same attributes for each field' do
  #       pivot.fields.each do |field|
  #         new_field = new_pivot.fields.where(name: field.name).first!

  #         expect(new_field.attributes.except(*%w(id pivot_id created_at updated_at))).to \
  #           match(field.attributes.except(*%w(id pivot_id created_at updated_at)))
  #       end
  #     end
  #   end
  # end

  describe "#new_year" do
    before do
      pivot.cropping_year = 2015
      pivot.save!
    end

    it "removes irrigaion events" do
      pivot.irrigation_events << IrrigationEvent.create
      expect(pivot.irrigation_events.length).to be 1
      expect { pivot.new_year }.to change { IrrigationEvent.count }
      expect(pivot.irrigation_events.length).to be 0
    end

    it "sets the croping year" do
      pivot.cropping_year = Date.today.year - 1
      pivot.save!
      pivot.reload
      expect { pivot.new_year }.to change { pivot.cropping_year }
      expect(pivot.cropping_year).to be Date.today.year
    end

    it "calls a new year for each field" do
      pivot.fields << Field.new
      # pivot.fields.each { |f| f.should_receive(:new_year).once }
      pivot.fields.each { |f| expect(f).to receive(:new_year).once }
      pivot.new_year
    end
  end

  describe "#destroy" do
    it "removes associated fields" do
      pivot.reload
      expect { pivot.destroy! }.to change { Field.count }
    end

    it "removes associated irrigation events" do
      pivot.reload
      pivot.irrigation_events << IrrigationEvent.create
      expect { pivot.destroy! }.to change { IrrigationEvent.count }
    end
  end
end
