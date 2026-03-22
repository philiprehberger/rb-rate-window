# frozen_string_literal: true

require_relative 'rate_window/version'
require_relative 'rate_window/tracker'

module Philiprehberger
  module RateWindow
    class Error < StandardError; end

    # Create a new rate window tracker.
    #
    # @param window [Numeric] window duration in seconds
    # @param resolution [Numeric] bucket size in seconds
    # @return [Tracker] a new tracker
    def self.new(window: 60, resolution: 1)
      Tracker.new(window: window, resolution: resolution)
    end
  end
end
