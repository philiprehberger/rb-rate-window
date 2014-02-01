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

    it 'raises on invalid percentile' do
      expect { tracker.percentile(-1) }
        .to raise_error(Philiprehberger::RateWindow::Error, /percentile must be between/)
      expect { tracker.percentile(101) }
        .to raise_error(Philiprehberger::RateWindow::Error, /percentile must be between/)
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
  end
end
