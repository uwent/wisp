class RingBuffer
  @vals = nil
  attr_accessor :last_nonzero

  EPSILON = 0.00000001

  def self.big_enough(val)
    val && (0.0 - val).abs > EPSILON
  end

  def initialize(size=10)
    @vals = Array.new(size)
    @last = -1
    @n_vals = 0
    @last_nonzero = nil
  end

  def add(val)
    return unless val # Ignore nils
    @last = (@last + 1) % @vals.size
    @vals[@last] = val
    @n_vals += 1 if @n_vals < @vals.size
    # record last nonzero value added
    @last_nonzero = val if RingBuffer.big_enough(val)
  end

  def max
    return nil unless @n_vals > 0
    @vals[0..@n_vals-1].max
  end

  def mean(ignore_zeros=false)
    return nil unless @n_vals > 0
    if ignore_zeros
      sum,num_nonzero_vals = @vals[0..@n_vals-1].inject([0.0,0]) do |sums, val|
        if RingBuffer.big_enough(val)
          [sums[0] + val,sums[1] + 1]
        else
          sums
        end
      end
      if num_nonzero_vals == 0
        nil
      else
        sum / num_nonzero_vals.to_f
      end
    else
      (@vals[0..@n_vals-1].inject(0.0) { |sum, val| sum + val } || 0.0).to_f / @n_vals.to_f
    end
  end

  def dump
    [@last,@n_vals,@vals]
  end
end
