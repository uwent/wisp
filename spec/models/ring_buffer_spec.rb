require 'rails_helper'

describe RingBuffer do
  let(:ring_buffer) { RingBuffer.new }
  let(:delta) { 2 ** -20 }

  describe '#last_nonzero' do
    let(:ring_buffer) { RingBuffer.new }
    let(:values) { [] }

    before do
      values.each do |value|
        ring_buffer.add(value.to_f)
      end
    end

    context 'when the buffer is empty' do
      it 'is nil' do
        expect(ring_buffer.last_nonzero).to be_nil
      end
    end

    context 'when the buffer only has zeroes' do
      let(:values) { [RingBuffer::EPSILON, 0, 0] }

      it 'is nil' do
        expect(ring_buffer.last_nonzero).to be_nil
      end
    end

    context 'when the buffer has non-zero values in it' do
      it 'is the last value added' do
        (1..10).to_a.shuffle.each do |value|
          ring_buffer.add(value.to_f)

          expect(ring_buffer.last_nonzero).to be_within(delta).of(value)

          ring_buffer.add(0)

          expect(ring_buffer.last_nonzero).to be_within(delta).of(value)
        end
      end
    end
  end

  describe '#mean' do
    [
      {
        size: 12,
        values: [0, 1, 2, 3, 4, 0, 10, 9, 8, 7],
        ignore_zero: false,
        expected: 4.4
      },
      {
        size: 12,
        values: [0, 1, 2, 3, 4, 0, 10, 9, 8, 7],
        ignore_zero: true,
        expected: 5.5
      },
      {
        size: 3,
        values: [0, 0, 0],
        ignore_zero: true,
        expected: nil
      },
      {
        size: 3,
        values: [],
        ignore_zero: true,
        expected: nil
      }
    ].each do |scenario|
      context "when the size is #{scenario[:size]}" do
        let(:ring_buffer) { RingBuffer.new(scenario[:size]) }

        before do
          scenario[:values].each do |value|
            ring_buffer.add(value.to_f)
          end
        end

        if scenario[:expected].nil?
          it 'is nil' do
            expect(ring_buffer.mean(scenario[:ignore_zero])).to be_nil
          end
        else
          it "is #{scenario[:expected]}" do
            expect(ring_buffer.mean(scenario[:ignore_zero])).to be_within(delta).of(scenario[:expected])
          end
        end
      end
    end


    context 'when zero is not ignored' do
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
  end

  describe '#max' do
    [
      {
        size: 3,
        values: [0, 1, 2, 3, 4],
        expected: 4.0
      },
      {
        size: 3,
        values: [0, 0],
        expected: 0.0
      }
    ].each do |scenario|
      context "when the size is #{scenario[:size]} and the values are #{scenario[:values]}" do
        let(:ring_buffer) { RingBuffer.new(scenario[:size]) }

        it "is #{scenario[:expected]}" do
          scenario[:values].each do |value|
            ring_buffer.add(value.to_f)
          end

          expect(ring_buffer.max).to be_within(delta).of(scenario[:expected])
        end
      end
    end
  end

  describe '#big_enough' do
    (0..7).each do |exponent|
      positive_value = (10 ** -exponent).to_f
      negative_value = -(10 ** -exponent).to_f

      context "when the value is #{positive_value}" do
        it 'is true' do
          expect(RingBuffer.big_enough(positive_value)).to be_truthy
        end
      end

      context "when the value is #{negative_value}" do
        it 'is true' do
          expect(RingBuffer.big_enough(negative_value)).to be_truthy
        end
      end
    end

    (8..10).each do |exponent|
      positive_value = (10 ** -exponent).to_f
      negative_value = -(10 ** -exponent).to_f

      context "when the value is #{positive_value}" do
        it 'is false' do
          expect(RingBuffer.big_enough(positive_value)).to be_falsey
        end
      end

      context "when the value is #{negative_value}" do
        it 'is false' do
          expect(RingBuffer.big_enough(negative_value)).to be_falsey
        end
      end
    end
  end
end
