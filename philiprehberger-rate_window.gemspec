# frozen_string_literal: true

require_relative 'lib/philiprehberger/rate_window/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-rate_window'
  spec.version       = Philiprehberger::RateWindow::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Time-windowed rate tracker with configurable resolution'
  spec.description   = 'Thread-safe time-windowed rate tracker that records values into bucketed time slots. ' \
                       'Supports rate calculation, sum, count, average, and percentile queries over a sliding window.'
  spec.homepage      = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-rate_window'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/philiprehberger/rb-rate-window'
  spec.metadata['changelog_uri']         = 'https://github.com/philiprehberger/rb-rate-window/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/philiprehberger/rb-rate-window/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
