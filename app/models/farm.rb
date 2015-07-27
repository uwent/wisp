class Farm < ActiveRecord::Base
  belongs_to :group
  has_many :pivots, dependent: :destroy

  validates :year, presence: true

  after_create :create_dependent_objects

  # TODO: rename to for_group
  def self.my_farms(group_id)
    where(group_id: group_id)
  end

  def self.latest_pivots(farms)
    latest_year = farms.collect { |f| f.pivots }.flatten.collect { |p| p.cropping_year }.max
    (farms.collect { |f| f.pivots }).flatten.select { |p| p.cropping_year == latest_year }
  end

  def problem
    problems.size > 0
  end

  # Iterate over all the fields on the farm. Return a hash where the keys are fields with problems,
  # the values are the FDW where the AD is negative today or in the next two days.
  def problems(date=Date.today)
    # Collect all fields on the farm
    all_fields = pivots.select { |p| p.cropping_year == date.year }.collect { |p| p.fields }.flatten
    # Is AD negative today or two days ahead?
    problems = all_fields.collect { |f| f.problem(date, date + 2) }.compact
    problems
  end

  def act # placeholder for dummy JSON info, to be replaced by "action" button in grid
    ""
  end

  def create_dependent_objects
    pivots.create!
  end

  def clone_pivots_for(year=Time.now.year)
    pivots.each do |piv|
      if (cloned = piv.clone_for(year))
        pivots << cloned
      end
    end
  end
end
