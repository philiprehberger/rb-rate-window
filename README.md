# philiprehberger-rate_window

[![Tests](https://github.com/philiprehberger/rb-rate-window/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-rate-window/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-rate_window.svg)](https://rubygems.org/gems/philiprehberger-rate_window)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-rate-window)](https://github.com/philiprehberger/rb-rate-window/commits/main)

Time-windowed rate tracker with configurable resolution

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-rate_window"
```

Or install directly:

```bash
gem install philiprehberger-rate_window
```

## Usage

```ruby
require "philiprehberger/rate_window"

tracker = Philiprehberger::RateWindow.new(window: 60, resolution: 1)

tracker.record(1)
tracker.record(5)
tracker.record(3)

tracker.rate      # => events per second over the window
tracker.sum       # => 9.0
tracker.count     # => 3
tracker.average   # => 3.0
```

### Percentiles

```ruby
tracker = Philiprehberger::RateWindow.new(window: 60, resolution: 1)
100.times { |i| tracker.record(i) }

tracker.percentile(50)   # => median value (with linear interpolation)
tracker.percentile(95)   # => 95th percentile
tracker.percentile(99)   # => 99th percentile
tracker.median           # => shortcut for percentile(50)
```

### Min / Max

```ruby
tracker = Philiprehberger::RateWindow.new(window: 60, resolution: 1)
tracker.record(5)
tracker.record(20)
tracker.record(3)

tracker.min   # => 3.0
tracker.max   # => 20.0
```

### Histogram

```ruby
tracker = Philiprehberger::RateWindow.new(window: 60, resolution: 1)
100.times { |i| tracker.record(i) }

tracker.histogram(buckets: 5)
# => [
#   { range: 0.0..20.0, count: ... },
#   { range: 20.0..40.0, count: ... },
#   ...
# ]
```

### Custom Resolution

```ruby
# 5-minute window with 10-second buckets
tracker = Philiprehberger::RateWindow.new(window: 300, resolution: 10)
tracker.record(42)
tracker.rate    # => rate per second over 5 minutes
```

### Reset

```ruby
tracker.reset
tracker.sum     # => 0.0
tracker.count   # => 0
```

## API

| Method | Description |
|--------|-------------|
| `.new(window:, resolution:)` | Create a tracker with window (seconds) and bucket resolution |
| `#record(value = 1)` | Record a value in the current time bucket |
| `#rate` | Calculate rate per second over the window |
| `#sum` | Sum of all values in the window |
| `#count` | Number of recordings in the window |
| `#average` | Average value per recording |
| `#percentile(p)` | Calculate percentile (0-100) with linear interpolation |
| `#median` | Shortcut for `percentile(50)` |
| `#min` | Minimum recorded value in the window |
| `#max` | Maximum recorded value in the window |
| `#histogram(buckets: 10)` | Value distribution as array of `{ range:, count: }` hashes |
| `#reset` | Clear all recorded data |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-rate-window)

🐛 [Report issues](https://github.com/philiprehberger/rb-rate-window/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-rate-window/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
