# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-04-18

### Added
- `Tracker#variance` and `Tracker#stddev` — population variance and standard deviation over the current window; also exposed under `:variance` / `:stddev` keys in `#snapshot`

## [0.5.0] - 2026-04-16

### Added
- `Tracker#snapshot` returns a plain hash with all stats (`sum`, `count`, `rate`, `average`, `min`, `max`, `median`, `p95`) computed atomically under a single mutex acquisition and a single cleanup pass

## [0.4.0] - 2026-04-16

### Added
- `Tracker#quantiles(*fractions)` returns a hash mapping each requested fraction (in `[0.0, 1.0]`) to its interpolated percentile value in a single pass, sharing the sorting logic with `#percentile`/`#median`/`#p95`

## [0.3.0] - 2026-04-15

### Added
- `p95` method as shortcut for 95th percentile

## [0.2.0] - 2026-04-03

### Added
- `median` method as shortcut for 50th percentile
- `min` and `max` tracking across the sliding window
- `histogram` method for value distribution analysis
- Improved `percentile` calculation with linear interpolation

## [0.1.4] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.3] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.2] - 2026-03-22

### Changed
- Expanded test suite to 30+ examples covering edge cases, error paths, and boundary conditions

## [0.1.1] - 2026-03-22

### Changed
- Version bump for republishing

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Time-windowed rate tracking with configurable window and resolution
- Record values into sliding time buckets
- Rate, sum, count, and average calculations
- Percentile queries over the window
- Thread-safe operations with mutex synchronization
- Automatic bucket cleanup on expired time slots
