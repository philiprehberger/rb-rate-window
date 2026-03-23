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
        Thread.new { 50.times { tracker.sum; tracker.count; tracker.rate } }
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
