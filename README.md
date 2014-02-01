# philiprehberger-rate_window

[![Tests](https://github.com/philiprehberger/rb-rate-window/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-rate-window/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-rate_window.svg)](https://rubygems.org/gems/philiprehberger-rate_window)
[![License](https://img.shields.io/github/license/philiprehberger/rb-rate-window)](LICENSE)

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

tracker.percentile(50)   # => median value
tracker.percentile(95)   # => 95th percentile
tracker.percentile(99)   # => 99th percentile
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
| `#percentile(p)` | Calculate percentile (0-100) of bucket values |
| `#reset` | Clear all recorded data |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
