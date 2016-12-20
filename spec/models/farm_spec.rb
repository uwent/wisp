require "rails_helper"

describe Farm do
  before do
    allow_any_instance_of(Field)
      .to receive(:date_endpoints)
      .and_return([Date.yesterday, Date.today])
    @group = Group.create()
  end

  describe '#validation' do
    it 'can create valid farm' do
      farm = Farm.new(year: Date.current.year)
      expect(farm).to be_valid
    end

    it 'is not valid without a year' do
      farm = Farm.new()
      expect(farm).not_to be_valid
    end

  end
  
  describe '#create_dependent_objects' do
    let(:farm ) { Farm.new(year: Date.current.year, group: @group) }
    it 'is called after create' do
      expect(farm).to receive(:create_dependent_objects)

      farm.save
    end

    it 'associates a pivot with the farm' do
      expect { farm.save }.to change { farm.pivots.empty? }.to(false)
    end
  end

  describe '#destroy' do
    let(:farm ) { Farm.new(year: Date.current.year, group: @group) }
    
    it 'removes associated pivots' do
      farm.save!
      farm.reload
      expect { farm.destroy! }.to change { Pivot.count }
    end
  end

  describe '#my_farms' do
    let(:farm ) { Farm.new(year: Date.current.year, group: @group) }

    it 'should be this farms\'s group\'s farms' do
      farm.save!
      farm.reload
      expect(Farm.my_farms(farm.group_id)).to eq @group.farms
    end
  end

  describe '#latest_pivots' do
    let(:farm ) { Farm.new(year: Date.current.year, group: @group) }
    it 'should return all pivots in the most recent year' do
      farm.save!
      expect(Farm.latest_pivots([farm])).to eq farm.pivots
    end
  end
end
