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
  
  def problems
    fields.inject([]) { |problems, field| problems << field.problem }
  end
  
  def set_default_et_method
    if self[:et_method_id]
      logger.info "That's odd, et_method_id was set to #{et_method_id} coming into Farm.create"
    else
      self[:et_method_id] = EtMethod.find_by_type('LaiEtMethod')[:id]
      logger.info "et_method_id now #{self[:et_method_id]}"
      raise "Could not find LAI ET method to set as default" unless self[:et_method_id]
    end
    logger.warn "Farm#set_default_et_method: #{self.inspect}" 
  end
  
  def create_default_data
    logger.warn "Farm#create_default_data: #{self.inspect}" 
    raise "Could not set default ET method" unless self[:et_method_id]
    pivots << Pivot.create(:name => "New pivot (farm: #{name})", :farm_id => self[:id])
  end
end
