class Farm < ActiveRecord::Base
  belongs_to :group
  has_many :pivots, dependent: :destroy

  validates :year, presence: true

  after_create :create_dependent_objects

  before_destroy :mother_may_i

  @@clobberable = nil

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
    pivots.create!(
      name: "New pivot (farm ID: #{id})",
      cropping_year: year || Time.now.year)
  end

  def mother_may_i
    if group.may_destroy(self)
      @@clobberable = id
      Pivot.destroy_all "farm_id = #{id}"
      return true
    else
      return false
    end
  end
  def may_destroy(pivot)
    pivots.size > 1 || @@clobberable == id
  end

  def clone_pivots_for(year=Time.now.year)
    pivots.each do |piv|
      if (cloned = piv.clone_for(year))
        pivots << cloned
      end
    end
  end
end
