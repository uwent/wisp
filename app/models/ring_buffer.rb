class RingBuffer
  attr_reader \
    :last_index,
    :last_nonzero,
    :array

  EPSILON = 0.00000001
  SIZE = 10

  def self.big_enough(value)
    value && (0.0 - value).abs > EPSILON
  end

  def initialize(size = SIZE)
    @array = Array.new(size)
    @last_index = -1
    @last_nonzero = nil
  end

  def add(value)
    return if value.nil?

    @last_index = (last_index + 1) % array.size

    array[last_index] = value

    @last_nonzero = value if RingBuffer.big_enough(value)
  end

  def max
    non_nil.max
  end

  def mean(ignore_zero = false)
    values = ignore_zero ? non_zero : non_nil

    return if values.none?

    values.sum / values.count
  end

  def mean_top_3
    top_3 = non_nil.sort.reverse[0...3]

    if top_3.empty?
      0.0
    else
      top_3.sum / top_3.length
    end
  end

  private

  def non_nil
    array.reject(&:nil?)
  end

  def non_zero
    non_nil.select do |value|
      RingBuffer.big_enough(value)
    end
  end
end
