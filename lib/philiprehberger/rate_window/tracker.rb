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
          @buckets[idx] += value.to_f
          @counts[idx] += 1
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

      # Calculate a percentile of bucket values.
      #
      # @param p [Numeric] percentile (0-100)
      # @return [Float] the percentile value
      def percentile(p)
        raise Error, 'percentile must be between 0 and 100' unless p.between?(0, 100)

        @mutex.synchronize do
          cleanup
          values = collect_values
          return 0.0 if values.empty?

          sorted = values.sort
          k = (p / 100.0 * (sorted.length - 1)).round
          sorted[k]
        end
      end

      # Reset all buckets.
      #
      # @return [self]
      def reset
        @mutex.synchronize do
          @buckets.fill(0.0)
          @counts.fill(0)
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
        elsif elapsed.positive?
          elapsed.times do |i|
            idx = (@last_bucket_index + 1 + i) % @bucket_count
            @buckets[idx] = 0.0
            @counts[idx] = 0
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
    end
  end
end
