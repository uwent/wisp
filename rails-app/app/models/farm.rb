class Farm < ActiveRecord::Base
  belongs_to :group
  belongs_to :et_method
  has_many :pivots, :dependent => :destroy
  validates :year, :presence => true
  before_create :set_default_et_method
  after_create :create_default_data
  
  def self.my_farms(group_id)
    Farm.find(:all, :conditions => ['group_id = ?',group_id])
  end
  
  def problem
    # FIXME: Should have code in here to actually iterate through the fields and detect problems!
    rand > 0.5 ? "Yes": ""
  end
  
  def set_default_et_method
    unless self[:et_method_id]
      et_method = (EtMethod.all.select {|etm| etm.class == LaiEtMethod}).first
    end
  end
  
  def create_default_data
  # puts self.inspect
    raise "Could not set default ET method" unless self[:et_method_id]
    pivots << Pivot.create(:name => "New pivot (farm: #{name})", :farm_id => self[:id])
  end
end
