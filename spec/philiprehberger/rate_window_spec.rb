# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::RateWindow do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::RateWindow::VERSION).not_to be_nil
    end
  end

  describe '.new' do
    it 'creates a Tracker instance' do
      tracker = described_class.new(window: 60, resolution: 1)
      expect(tracker).to be_a(Philiprehberger::RateWindow::Tracker)
    end

    it 'raises on non-positive window' do
      expect { described_class.new(window: 0, resolution: 1) }
        .to raise_error(Philiprehberger::RateWindow::Error, /window must be positive/)
    end

    it 'raises on non-positive resolution' do
      expect { described_class.new(window: 60, resolution: 0) }
        .to raise_error(Philiprehberger::RateWindow::Error, /resolution must be positive/)
    end

    it 'raises when resolution exceeds window' do
      expect { described_class.new(window: 10, resolution: 20) }
        .to raise_error(Philiprehberger::RateWindow::Error, /resolution must be <= window/)
    end

    it 'raises on negative window' do
      expect { described_class.new(window: -5, resolution: 1) }
        .to raise_error(Philiprehberger::RateWindow::Error, /window must be positive/)
    end

    it 'raises on negative resolution' do
      expect { described_class.new(window: 60, resolution: -1) }
        .to raise_error(Philiprehberger::RateWindow::Error, /resolution must be positive/)
    end

    it 'accepts equal window and resolution' do
      tracker = described_class.new(window: 5, resolution: 5)
      expect(tracker).to be_a(Philiprehberger::RateWindow::Tracker)
    end

    it 'uses default values when not specified' do
      tracker = described_class.new
      expect(tracker).to be_a(Philiprehberger::RateWindow::Tracker)
    end
  end

  describe '#record and #sum' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'records and sums values' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)

      expect(tracker.sum).to eq(60.0)
    end

    it 'defaults value to 1' do
      tracker.record
      tracker.record
      tracker.record

      expect(tracker.sum).to eq(3.0)
    end

    it 'returns self from record for chaining' do
      result = tracker.record(5)
      expect(result).to eq(tracker)
    end

    it 'chains multiple records' do
      tracker.record(1).record(2).record(3)
      expect(tracker.sum).to eq(6.0)
    end

    it 'handles float values' do
      tracker.record(1.5)
      tracker.record(2.5)
      expect(tracker.sum).to eq(4.0)
    end

    it 'handles large number of recordings' do
      100.times { tracker.record(1) }
      expect(tracker.sum).to eq(100.0)
    end
  end

  describe '#count' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'counts recordings' do
      tracker.record(5)
      tracker.record(10)

      expect(tracker.count).to eq(2)
    end

    it 'starts at zero' do
      expect(tracker.count).to eq(0)
    end

    it 'counts each recording regardless of value' do
      tracker.record(100)
      tracker.record(0)
      tracker.record(-5)
      expect(tracker.count).to eq(3)
    end

    it 'returns an Integer' do
      tracker.record(1)
      expect(tracker.count).to be_a(Integer)
    end
  end

  describe '#rate' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'calculates rate per second' do
      tracker.record(120)

      rate = tracker.rate
      expect(rate).to eq(2.0)
    end

    it 'returns zero with no recordings' do
      expect(tracker.rate).to eq(0.0)
    end

    it 'returns a Float' do
      expect(tracker.rate).to be_a(Float)
    end

    it 'calculates rate based on window size' do
      small_window = described_class.new(window: 10, resolution: 1)
      small_window.record(50)
      expect(small_window.rate).to eq(5.0)
    end
  end

  describe '#average' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'calculates average per recording' do
      tracker.record(10)
      tracker.record(20)

      expect(tracker.average).to eq(15.0)
    end

    it 'returns zero with no recordings' do
      expect(tracker.average).to eq(0.0)
    end

    it 'returns a Float' do
      tracker.record(1)
      expect(tracker.average).to be_a(Float)
    end

    it 'handles single recording' do
      tracker.record(42)
      expect(tracker.average).to eq(42.0)
    end
  end

  describe '#percentile' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns a numeric value' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)

      expect(tracker.percentile(50)).to be_a(Float)
    end

    it 'returns zero with no recordings' do
      expect(tracker.percentile(50)).to eq(0.0)
    end

    it 'raises on invalid percentile below 0' do
      expect { tracker.percentile(-1) }
        .to raise_error(Philiprehberger::RateWindow::Error, /percentile must be between/)
    end

    it 'raises on invalid percentile above 100' do
      expect { tracker.percentile(101) }
        .to raise_error(Philiprehberger::RateWindow::Error, /percentile must be between/)
    end

    it 'accepts 0th percentile' do
      tracker.record(5)
      expect { tracker.percentile(0) }.not_to raise_error
    end

    it 'accepts 100th percentile' do
      tracker.record(5)
      expect { tracker.percentile(100) }.not_to raise_error
    end

    it 'returns a Float for boundary percentiles' do
      tracker.record(10)
      expect(tracker.percentile(0)).to be_a(Float)
      expect(tracker.percentile(100)).to be_a(Float)
    end
  end

  describe '#median' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns the median of recorded values' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)
      expect(tracker.median).to be_a(Float)
    end

    it 'returns zero with no recordings' do
      expect(tracker.median).to eq(0.0)
    end

    it 'returns the single value when only one recording' do
      tracker.record(42)
      expect(tracker.median).to eq(42.0)
    end

    it 'is equal to percentile(50)' do
      tracker.record(5)
      tracker.record(15)
      tracker.record(25)
      expect(tracker.median).to eq(tracker.percentile(50))
    end

    it 'interpolates between two bucket values' do
      # Use small resolution so records land in different buckets
      t = described_class.new(window: 60, resolution: 0.001)
      t.record(10)
      sleep(0.002)
      t.record(20)
      expect(t.median).to eq(15.0)
    end

    it 'handles all same values in one bucket' do
      tracker.record(7)
      expect(tracker.median).to eq(7.0)
    end
  end

  describe '#p95' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'matches percentile(95) on identical input' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)
      expect(tracker.p95).to eq(tracker.percentile(95))
    end

    it 'returns the same value as percentile(95) on an empty tracker' do
      expect(tracker.p95).to eq(tracker.percentile(95))
    end

    it 'returns zero on empty tracker' do
      expect(tracker.p95).to eq(0.0)
    end

    it 'matches the 95th percentile after adding 100 values' do
      t = described_class.new(window: 60, resolution: 0.001)
      100.times do |i|
        t.record(i)
        sleep(0.002)
      end
      expect(t.p95).to eq(t.percentile(95))
    end

    it 'returns a Float' do
      tracker.record(5)
      expect(tracker.p95).to be_a(Float)
    end
  end

  describe '#min' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns the minimum recorded value' do
      tracker.record(10)
      tracker.record(5)
      tracker.record(20)
      expect(tracker.min).to eq(5.0)
    end

    it 'returns zero with no recordings' do
      expect(tracker.min).to eq(0.0)
    end

    it 'handles single value' do
      tracker.record(42)
      expect(tracker.min).to eq(42.0)
    end

    it 'handles negative values' do
      tracker.record(-5)
      tracker.record(10)
      expect(tracker.min).to eq(-5.0)
    end

    it 'handles all same values' do
      3.times { tracker.record(7) }
      expect(tracker.min).to eq(7.0)
    end

    it 'returns a Float' do
      tracker.record(3)
      expect(tracker.min).to be_a(Float)
    end

    it 'resets to zero after reset' do
      tracker.record(5)
      tracker.reset
      expect(tracker.min).to eq(0.0)
    end
  end

  describe '#max' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns the maximum recorded value' do
      tracker.record(10)
      tracker.record(5)
      tracker.record(20)
      expect(tracker.max).to eq(20.0)
    end

    it 'returns zero with no recordings' do
      expect(tracker.max).to eq(0.0)
    end

    it 'handles single value' do
      tracker.record(42)
      expect(tracker.max).to eq(42.0)
    end

    it 'handles negative values' do
      tracker.record(-5)
      tracker.record(-10)
      expect(tracker.max).to eq(-5.0)
    end

    it 'handles all same values' do
      3.times { tracker.record(7) }
      expect(tracker.max).to eq(7.0)
    end

    it 'returns a Float' do
      tracker.record(3)
      expect(tracker.max).to be_a(Float)
    end

    it 'resets to zero after reset' do
      tracker.record(5)
      tracker.reset
      expect(tracker.max).to eq(0.0)
    end
  end

  describe '#histogram' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns an array of hashes with range and count' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)
      result = tracker.histogram(buckets: 3)
      expect(result).to be_an(Array)
      expect(result.first).to have_key(:range)
      expect(result.first).to have_key(:count)
    end

    it 'returns empty array with no recordings' do
      expect(tracker.histogram).to eq([])
    end

    it 'returns single bucket when all values are the same' do
      # All records in same bucket sum to 15, which is one value
      3.times { tracker.record(5) }
      result = tracker.histogram(buckets: 5)
      expect(result.length).to eq(1)
      expect(result[0][:count]).to eq(1)
    end

    it 'distributes values across buckets' do
      t = described_class.new(window: 60, resolution: 0.001)
      t.record(0)
      sleep(0.002)
      t.record(50)
      sleep(0.002)
      t.record(100)
      result = t.histogram(buckets: 2)
      expect(result.length).to eq(2)
      total = result.sum { |h| h[:count] }
      expect(total).to eq(3)
    end

    it 'uses default of 10 buckets' do
      t = described_class.new(window: 60, resolution: 0.001)
      10.times do |i|
        t.record(i * 10)
        sleep(0.002)
      end
      result = t.histogram
      expect(result.length).to eq(10)
    end

    it 'raises on non-positive bucket count' do
      expect { tracker.histogram(buckets: 0) }
        .to raise_error(Philiprehberger::RateWindow::Error, /buckets must be positive/)
    end

    it 'handles single value' do
      tracker.record(42)
      result = tracker.histogram(buckets: 5)
      expect(result.length).to eq(1)
      expect(result[0][:count]).to eq(1)
    end

    it 'total count matches number of active buckets' do
      t = described_class.new(window: 60, resolution: 0.001)
      t.record(1)
      sleep(0.02)
      t.record(2)
      sleep(0.02)
      t.record(3)
      result = t.histogram(buckets: 3)
      total = result.sum { |h| h[:count] }
      expect(total).to eq(3)
    end

    it 'ranges cover min to max' do
      t = described_class.new(window: 60, resolution: 0.001)
      t.record(10)
      sleep(0.02)
      t.record(50)
      result = t.histogram(buckets: 4)
      expect(result.first[:range].begin).to eq(10.0)
      expect(result.last[:range].end).to eq(50.0)
    end
  end

  describe '#quantiles' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns a hash keyed by the requested fractions' do
      t = described_class.new(window: 60, resolution: 0.001)
      10.times do |i|
        t.record(i + 1)
        sleep(0.002)
      end

      result = t.quantiles(0.25, 0.5, 0.75)

      expect(result).to be_a(Hash)
      expect(result.keys).to eq([0.25, 0.5, 0.75])
    end

    it 'returns values matching the equivalent percentile call' do
      t = described_class.new(window: 60, resolution: 0.001)
      [3, 1, 4, 1, 5, 9, 2, 6, 5, 3].each do |v|
        t.record(v)
        sleep(0.002)
      end

      result = t.quantiles(0.25, 0.5, 0.75, 0.95)

      expect(result[0.25]).to eq(t.percentile(25))
      expect(result[0.5]).to eq(t.percentile(50))
      expect(result[0.75]).to eq(t.percentile(75))
      expect(result[0.95]).to eq(t.percentile(95))
    end

    it 'accepts 0.0 and 1.0 as valid fractions' do
      t = described_class.new(window: 60, resolution: 0.001)
      (1..5).each do |v|
        t.record(v)
        sleep(0.002)
      end

      result = t.quantiles(0.0, 1.0)

      expect(result[0.0]).to eq(1.0)
      expect(result[1.0]).to eq(5.0)
    end

    it 'returns zero for each fraction on an empty tracker (matches #percentile)' do
      result = tracker.quantiles(0.25, 0.5, 0.75)

      expect(result).to eq({ 0.25 => 0.0, 0.5 => 0.0, 0.75 => 0.0 })
    end

    it 'supports a single fraction' do
      t = described_class.new(window: 60, resolution: 0.001)
      (1..4).each do |v|
        t.record(v)
        sleep(0.002)
      end

      result = t.quantiles(0.5)

      expect(result).to eq({ 0.5 => 2.5 })
    end

    it 'preserves the order of requested fractions' do
      t = described_class.new(window: 60, resolution: 0.001)
      (1..10).each do |v|
        t.record(v)
        sleep(0.002)
      end

      result = t.quantiles(0.9, 0.1, 0.5)

      expect(result.keys).to eq([0.9, 0.1, 0.5])
    end

    it 'raises ArgumentError for a fraction below 0.0' do
      tracker.record(1)

      expect { tracker.quantiles(-0.1) }
        .to raise_error(ArgumentError, /fractions must be between 0.0 and 1.0/)
    end

    it 'raises ArgumentError for a fraction above 1.0' do
      tracker.record(1)

      expect { tracker.quantiles(1.5) }
        .to raise_error(ArgumentError, /fractions must be between 0.0 and 1.0/)
    end

    it 'raises ArgumentError when any fraction in a list is invalid' do
      tracker.record(1)

      expect { tracker.quantiles(0.25, 0.5, 2.0) }
        .to raise_error(ArgumentError, /fractions must be between 0.0 and 1.0/)
    end

    it 'raises ArgumentError for non-numeric fractions' do
      tracker.record(1)

      expect { tracker.quantiles('half') }
        .to raise_error(ArgumentError, /fractions must be between 0.0 and 1.0/)
    end

    it 'returns Float values' do
      t = described_class.new(window: 60, resolution: 0.001)
      (1..5).each do |v|
        t.record(v)
        sleep(0.002)
      end

      result = t.quantiles(0.25, 0.75)

      result.each_value { |v| expect(v).to be_a(Float) }
    end

    it 'handles a single recording across all fractions' do
      tracker.record(42)

      result = tracker.quantiles(0.25, 0.5, 0.75)

      expect(result).to eq({ 0.25 => 42.0, 0.5 => 42.0, 0.75 => 42.0 })
    end

    it 'is consistent across multiple quantile orderings' do
      t = described_class.new(window: 60, resolution: 0.001)
      (1..20).each do |v|
        t.record(v)
        sleep(0.002)
      end

      forward = t.quantiles(0.1, 0.5, 0.9)
      reversed = t.quantiles(0.9, 0.5, 0.1)

      expect(forward[0.1]).to eq(reversed[0.1])
      expect(forward[0.5]).to eq(reversed[0.5])
      expect(forward[0.9]).to eq(reversed[0.9])
    end
  end

  describe '#variance' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns 0.0 on an empty tracker' do
      expect(tracker.variance).to eq(0.0)
    end

    it 'returns 0.0 for a single value' do
      tracker.record(42)
      expect(tracker.variance).to eq(0.0)
    end

    it 'computes population variance for a known dataset' do
      t = described_class.new(window: 60, resolution: 0.001)
      [2, 4, 4, 4, 5, 5, 7, 9].each do |v|
        t.record(v)
        sleep(0.002)
      end
      expect(t.variance).to eq(4.0)
    end

    it 'excludes values outside the current window' do
      t = described_class.new(window: 0.05, resolution: 0.01)
      t.record(100)
      sleep(0.1)
      t.record(5)
      expect(t.variance).to eq(0.0)
    end

    it 'returns a Float' do
      tracker.record(1)
      expect(tracker.variance).to be_a(Float)
    end
  end

  describe '#stddev' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns 0.0 on an empty tracker' do
      expect(tracker.stddev).to eq(0.0)
    end

    it 'returns 0.0 for a single value' do
      tracker.record(42)
      expect(tracker.stddev).to eq(0.0)
    end

    it 'computes population stddev for a known dataset' do
      t = described_class.new(window: 60, resolution: 0.001)
      [2, 4, 4, 4, 5, 5, 7, 9].each do |v|
        t.record(v)
        sleep(0.002)
      end
      expect(t.stddev).to eq(2.0)
    end

    it 'excludes values outside the current window' do
      t = described_class.new(window: 0.05, resolution: 0.01)
      t.record(100)
      sleep(0.1)
      t.record(5)
      expect(t.stddev).to eq(0.0)
    end

    it 'returns a Float' do
      tracker.record(1)
      expect(tracker.stddev).to be_a(Float)
    end
  end

  describe '#snapshot' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'returns a hash with all expected keys' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)

      result = tracker.snapshot

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly(
        :sum, :count, :rate, :average, :min, :max, :median, :p95, :variance, :stddev
      )
    end

    it 'includes :variance and :stddev keys' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)

      result = tracker.snapshot

      expect(result).to include(:variance, :stddev)
      expect(result[:variance]).to be_a(Float)
      expect(result[:stddev]).to be_a(Float)
    end

    it 'returns correct values with data' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)

      result = tracker.snapshot

      expect(result[:sum]).to eq(60.0)
      expect(result[:count]).to eq(3)
      expect(result[:rate]).to eq(1.0)
      expect(result[:average]).to eq(20.0)
      expect(result[:min]).to eq(10.0)
      expect(result[:max]).to eq(30.0)
      expect(result[:median]).to be_a(Float)
      expect(result[:p95]).to be_a(Float)
    end

    it 'returns zero/safe values for an empty tracker' do
      result = tracker.snapshot

      expect(result[:sum]).to eq(0.0)
      expect(result[:count]).to eq(0)
      expect(result[:rate]).to eq(0.0)
      expect(result[:average]).to eq(0.0)
      expect(result[:min]).to eq(0.0)
      expect(result[:max]).to eq(0.0)
      expect(result[:median]).to eq(0.0)
      expect(result[:p95]).to eq(0.0)
      expect(result[:variance]).to eq(0.0)
      expect(result[:stddev]).to eq(0.0)
    end

    it 'is consistent: all values reflect the same instant' do
      tracker.record(5)
      tracker.record(15)
      tracker.record(25)

      snap = tracker.snapshot

      expect(snap[:sum]).to eq(tracker.sum)
      expect(snap[:count]).to eq(tracker.count)
      expect(snap[:rate]).to eq(tracker.rate)
      expect(snap[:average]).to eq(tracker.average)
      expect(snap[:min]).to eq(tracker.min)
      expect(snap[:max]).to eq(tracker.max)
      expect(snap[:median]).to eq(tracker.median)
      expect(snap[:p95]).to eq(tracker.p95)
    end

    it 'median and p95 match their individual method equivalents' do
      tracker.record(10)
      tracker.record(20)
      tracker.record(30)

      snap = tracker.snapshot

      expect(snap[:median]).to eq(tracker.median)
      expect(snap[:p95]).to eq(tracker.p95)
    end

    it 'returns Float for numeric fields' do
      tracker.record(7)

      snap = tracker.snapshot

      expect(snap[:sum]).to be_a(Float)
      expect(snap[:rate]).to be_a(Float)
      expect(snap[:average]).to be_a(Float)
      expect(snap[:min]).to be_a(Float)
      expect(snap[:max]).to be_a(Float)
      expect(snap[:median]).to be_a(Float)
      expect(snap[:p95]).to be_a(Float)
    end

    it 'returns Integer for count' do
      tracker.record(1)
      expect(tracker.snapshot[:count]).to be_a(Integer)
    end
  end

  describe '#reset' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'clears all data' do
      tracker.record(10)
      tracker.record(20)
      tracker.reset

      expect(tracker.sum).to eq(0.0)
      expect(tracker.count).to eq(0)
      expect(tracker.rate).to eq(0.0)
    end

    it 'returns self for chaining' do
      result = tracker.reset
      expect(result).to eq(tracker)
    end

    it 'allows recording after reset' do
      tracker.record(10)
      tracker.reset
      tracker.record(5)
      expect(tracker.sum).to eq(5.0)
      expect(tracker.count).to eq(1)
    end

    it 'resets average to zero' do
      tracker.record(100)
      tracker.reset
      expect(tracker.average).to eq(0.0)
    end

    it 'resets percentile to zero' do
      tracker.record(50)
      tracker.reset
      expect(tracker.percentile(50)).to eq(0.0)
    end

    it 'resets min and max to zero' do
      tracker.record(10)
      tracker.record(20)
      tracker.reset
      expect(tracker.min).to eq(0.0)
      expect(tracker.max).to eq(0.0)
    end

    it 'resets histogram to empty' do
      tracker.record(10)
      tracker.reset
      expect(tracker.histogram).to eq([])
    end
  end

  describe 'thread safety' do
    let(:tracker) { described_class.new(window: 60, resolution: 1) }

    it 'handles concurrent recordings' do
      threads = 10.times.map do
        Thread.new { 100.times { tracker.record(1) } }
      end
      threads.each(&:join)

      expect(tracker.count).to eq(1000)
      expect(tracker.sum).to eq(1000.0)
    end

    it 'handles concurrent reads and writes' do
      threads = []
      threads += 5.times.map do
        Thread.new { 50.times { tracker.record(1) } }
      end
      threads += 5.times.map do
        Thread.new do
          50.times do
            tracker.sum
            tracker.count
            tracker.rate
          end
        end
      end
      threads.each(&:join)

      expect(tracker.count).to eq(250)
    end
  end

  describe 'window behavior' do
    it 'uses small window correctly' do
      tracker = described_class.new(window: 1, resolution: 0.1)
      tracker.record(10)
      expect(tracker.sum).to eq(10.0)
    end

    it 'uses matching window and resolution' do
      tracker = described_class.new(window: 5, resolution: 5)
      tracker.record(25)
      expect(tracker.rate).to eq(5.0)
    end
  end
end
