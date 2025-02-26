# frozen_string_literal: true

module Philiprehberger
  module RateWindow
    # Thread-safe time-windowed rate tracker with configurable resolution.
    class Tracker
      # @param window [Numeric] window duration in seconds
      # @param resolution [Numeric] bucket size in seconds
      def initialize(window: 60, resolution: 1)
        raise Error, 'window must be positive' unless window.positive?
        raise Error, 'resolution must be positive' unless resolution.positive?
        raise Error, 'resolution must be <= window' unless resolution <= window

        @window = window.to_f
        @resolution = resolution.to_f
        @bucket_count = (@window / @resolution).ceil
        @mutex = Mutex.new
        @buckets = Array.new(@bucket_count, 0.0)
        @counts = Array.new(@bucket_count, 0)
        @mins = Array.new(@bucket_count, Float::INFINITY)
        @maxs = Array.new(@bucket_count, -Float::INFINITY)
        @last_bucket_index = current_bucket_index
        @last_time = now
      end

      # Record a value in the current time bucket.
      #
      # @param value [Numeric] the value to record (default: 1)
      # @return [self]
      def record(value = 1)
        @mutex.synchronize do
          cleanup
          idx = current_bucket_index % @bucket_count
          val = value.to_f
          @buckets[idx] += val
          @counts[idx] += 1
          @mins[idx] = val if val < @mins[idx]
          @maxs[idx] = val if val > @maxs[idx]
        end
        self
      end

      # Calculate the rate per second over the window.
      #
      # @return [Float] rate per second
      def rate
        @mutex.synchronize do
          cleanup
          total = @buckets.sum
          total / @window
        end
      end

      # Sum of all values in the window.
      #
      # @return [Float]
      def sum
        @mutex.synchronize do
          cleanup
          @buckets.sum
        end
      end

      # Number of recordings in the window.
      #
      # @return [Integer]
      def count
        @mutex.synchronize do
          cleanup
          @counts.sum
        end
      end

      # Average value per recording in the window.
      #
      # @return [Float] average, or 0.0 if no recordings
      def average
        @mutex.synchronize do
          cleanup
          total_count = @counts.sum
          return 0.0 if total_count.zero?

          @buckets.sum / total_count
        end
      end

      # Calculate a percentile of recorded values using linear interpolation.
      #
      # @param p [Numeric] percentile (0-100)
      # @return [Float] the percentile value
      def percentile(p)
        raise Error, 'percentile must be between 0 and 100' unless p.between?(0, 100)

        @mutex.synchronize do
          cleanup
          values = collect_values
          return 0.0 if values.empty?

          interpolate(values.sort, p / 100.0)
        end
      end

      # Median value across active buckets (shortcut for percentile(50)).
      #
      # @return [Float] the median value
      def median
        percentile(50)
      end

      # 95th percentile value across active buckets (shortcut for percentile(95)).
      #
      # @return [Float] the 95th percentile value
      def p95
        percentile(95)
      end

      # Compute multiple quantiles in a single pass (sorted once).
      #
      # @param fractions [Array<Float>] quantile fractions in [0.0, 1.0]
      # @return [Hash{Float => Float}] mapping of fraction to interpolated value
      # @raise [ArgumentError] if any fraction is outside [0.0, 1.0]
      def quantiles(*fractions)
        fractions.each do |fraction|
          unless fraction.is_a?(Numeric) && fraction.between?(0.0, 1.0)
            raise ArgumentError, 'fractions must be between 0.0 and 1.0 inclusive'
          end
        end

        @mutex.synchronize do
          cleanup
          values = collect_values
          if values.empty?
            return fractions.to_h { |fraction| [fraction, 0.0] }
          end

          sorted = values.sort
          fractions.to_h do |fraction|
            [fraction, interpolate(sorted, fraction)]
          end
        end
      end

      # Minimum recorded value in the current window.
      #
      # @return [Float] minimum value, or 0.0 if no recordings
      def min
        @mutex.synchronize do
          cleanup
          result = Float::INFINITY
          @bucket_count.times do |i|
            result = @mins[i] if @counts[i].positive? && @mins[i] < result
          end
          result == Float::INFINITY ? 0.0 : result
        end
      end

      # Maximum recorded value in the current window.
      #
      # @return [Float] maximum value, or 0.0 if no recordings
      def max
        @mutex.synchronize do
          cleanup
          result = -Float::INFINITY
          @bucket_count.times do |i|
            result = @maxs[i] if @counts[i].positive? && @maxs[i] > result
          end
          result == -Float::INFINITY ? 0.0 : result
        end
      end

      # Returns a histogram of value distribution across equal-width buckets.
      #
      # @param buckets [Integer] number of histogram buckets (default: 10)
      # @return [Array<Hash>] array of { range:, count: } hashes
      def histogram(buckets: 10)
        raise Error, 'buckets must be positive' unless buckets.positive?

        @mutex.synchronize do
          cleanup
          values = collect_values
          return [] if values.empty?

          min_val = values.min
          max_val = values.max

          if min_val == max_val
            return [{ range: (min_val..max_val), count: values.length }]
          end

          width = (max_val - min_val).to_f / buckets
          result = Array.new(buckets) do |i|
            range_start = min_val + (i * width)
            range_end = min_val + ((i + 1) * width)
            { range: (range_start..range_end), count: 0 }
          end

          values.each do |v|
            idx = ((v - min_val) / width).floor
            idx = buckets - 1 if idx >= buckets
            result[idx][:count] += 1
          end

          result
        end
      end

      # Take an atomic snapshot of all stats in a single mutex acquisition.
      #
      # Runs cleanup once, then computes sum, count, rate, average, min, max,
      # median, and p95 in a single pass under the same lock.
      #
      # @return [Hash] snapshot with keys :sum, :count, :rate, :average,
      #   :min, :max, :median, :p95. Returns zero/nil-safe values for an
      #   empty tracker.
      def snapshot
        @mutex.synchronize do
          cleanup

          total_sum = @buckets.sum
          total_count = @counts.sum

          min_val = Float::INFINITY
          max_val = -Float::INFINITY
          @bucket_count.times do |i|
            if @counts[i].positive?
              min_val = @mins[i] if @mins[i] < min_val
              max_val = @maxs[i] if @maxs[i] > max_val
            end
          end

          values = collect_values
          sorted = values.sort

          {
            sum: total_sum,
            count: total_count,
            rate: total_sum / @window,
            average: total_count.zero? ? 0.0 : total_sum / total_count,
            min: min_val == Float::INFINITY ? 0.0 : min_val,
            max: max_val == -Float::INFINITY ? 0.0 : max_val,
            median: sorted.empty? ? 0.0 : interpolate(sorted, 0.5),
            p95: sorted.empty? ? 0.0 : interpolate(sorted, 0.95)
          }
        end
      end

      # Reset all buckets.
      #
      # @return [self]
      def reset
        @mutex.synchronize do
          @buckets.fill(0.0)
          @counts.fill(0)
          @mins.fill(Float::INFINITY)
          @maxs.fill(-Float::INFINITY)
          @last_bucket_index = current_bucket_index
          @last_time = now
        end
        self
      end

      private

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def current_bucket_index
        (now / @resolution).floor
      end

      def cleanup
        current = current_bucket_index
        elapsed = current - @last_bucket_index

        if elapsed >= @bucket_count
          @buckets.fill(0.0)
          @counts.fill(0)
          @mins.fill(Float::INFINITY)
          @maxs.fill(-Float::INFINITY)
        elsif elapsed.positive?
          elapsed.times do |i|
            idx = (@last_bucket_index + 1 + i) % @bucket_count
            @buckets[idx] = 0.0
            @counts[idx] = 0
            @mins[idx] = Float::INFINITY
            @maxs[idx] = -Float::INFINITY
          end
        end

        @last_bucket_index = current
        @last_time = now
      end

      def collect_values
        result = []
        @bucket_count.times do |i|
          result << @buckets[i] if @counts[i].positive?
        end
        result
      end

      def interpolate(sorted, fraction)
        rank = fraction * (sorted.length - 1)
        lower = rank.floor
        upper = rank.ceil

        return sorted[lower].to_f if lower == upper

        weight = rank - lower
        (sorted[lower] + (weight * (sorted[upper] - sorted[lower]))).to_f
      end
    end
  end
end
