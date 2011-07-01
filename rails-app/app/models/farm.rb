class Farm < ActiveRecord::Base
  belongs_to :group
  belongs_to :et_method
  has_many :pivots
  
  def self.my_farms(group_id)
    Farm.find(:all, :conditions => ['group_id = ?',group_id])
  end
  
  def problem
    # FIXME: Should have code in here to actually iterate through the fields and detect problems!
    rand > 0.5 ? "Yes": ""
  end
end
