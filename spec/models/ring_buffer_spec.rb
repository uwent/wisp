require 'rails_helper'

describe RingBuffer do
  let(:ring_buffer) { RingBuffer.new }
  let(:delta) { 2 ** -20 }

  describe '#mean' do
    context 'when no values are added' do
      it 'is nil' do
        expect(ring_buffer.mean).to be_nil
      end
    end

    context 'when -1.0 is added' do
      before { ring_buffer.add(-1.0) }

      it 'is -1.0' do
        expect(ring_buffer.mean).to be_within(delta).of(-1.0)
      end
    end

    context 'when -1.0 and 1.0 are added' do
      before do
        ring_buffer.add(-1.0)
        ring_buffer.add(1.0)
      end

      it 'is 0.0' do
        expect(ring_buffer.mean).to be_within(delta).of(0.0)
      end
    end

    context 'when it is filled' do
      before do
        (0..9).map(&:to_f).each do |value|
          ring_buffer.add(value)
        end
      end

      it 'is 4.5' do
        expect(ring_buffer.mean).to be_within(delta).of(4.5)
      end

      context 'and another value is added' do
        before { ring_buffer.add(11.0) }

        it 'is 5.6' do
          expect(ring_buffer.mean).to be_within(delta).of(5.6)
        end
      end
    end

    context 'when the size is specified' do
      let(:ring_buffer) { RingBuffer.new(5) }

      before { (0..5).map(&:to_f).each { |value| ring_buffer.add(value) } }

      it 'is the mean of the last 5' do
        expect(ring_buffer.mean).to be_within(delta).of(3.0)
      end
    end
  end

  #
  #
  # test "RingBuffer max works" do
  #   rb = RingBuffer.new(3)
  #   5.times { |ii| rb.add(ii.to_f) } # Should end up with [3,4,2]
  #   assert_equal(4.0, rb.max)
  # end
  #
  # test "RingBuffer big_enough works" do
  #   {0.1 => true, -0.1 => true, 0.0 => false, 0.00001 => true, -0.00001 => true, 0.000000000001 => false, -0.0000000000001 => false}.each do |val,expected|
  #     assert_equal(expected, RingBuffer.big_enough(val))
  #   end
  # end
  #
  # test "RingBuffer ignore_zeros works" do
  #   rb = RingBuffer.new(12)
  #   5.times { |ii| rb.add(ii.to_f) } # [0,1,2,3,4]
  #   rb.add(0.0) # Put a zero in the middle, to flush out ordering effects
  #   10.downto(7) {|ii| rb.add(ii.to_f) } # [0,1,2,3,4,0,10,9,8,7]
  #   # Sum is 44, counting ten values should get a mean of 4.4
  #   assert_in_delta(4.4, rb.mean, 2 ** -20)
  #   # But throwing out the zero values, should be 44 / 8 = 5.5
  #   assert_in_delta(5.5, rb.mean(true), 2 ** -20)
  # end
  #
  # test "RingBuffer ignore_zeros returns nil when called on an all-zero buffer" do
  #   rb = RingBuffer.new(3)
  #   assert_nil(rb.mean(true),'Should return nil when called on empty buffer with ignore_zeros flag')
  #   3.times { rb.add(0.0)}
  #   assert_nil(rb.mean(true),'Should return nil when called on buffer full of zeros with ignore_zeros flag')
  # end
  #
  # test "RingBuffer last_nonzero works" do
  #   rb = RingBuffer.new(6)
  #   assert_nil(rb.last_nonzero,'last_nonzero should return nil on empty buffer')
  #   [0.0,0.0].each { |val| rb.add(val) }
  #   assert_nil(rb.last_nonzero,'last_nonzero should return nil on buffer with nothing but zeros')
  #   rb.add(1.0)
  #   assert_in_delta(1.0, rb.last_nonzero, 2 ** -20)
  #   rb.add(0.0)
  #   assert_in_delta(1.0, rb.last_nonzero, 2 ** -20)
  #   rb.add(2.0)
  #   assert_in_delta(2.0, rb.last_nonzero, 2 ** -20)
  #   rb.add(-4.0)
  #   assert_in_delta(-4.0, rb.last_nonzero, 2 ** -20)
  # end
end
