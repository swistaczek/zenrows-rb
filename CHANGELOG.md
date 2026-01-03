# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-01-03

### Added

- Adaptive Stealth Mode support (`mode: "auto"`) - automatically selects optimal configurations while minimizing costs
- `VALID_MODES` constant for mode validation
- Warnings when `js_render` or `premium_proxy` are set with `mode: "auto"` (ignored, auto-managed by ZenRows)

## [0.3.0] - 2025-12-30

### Added

- Hooks/callbacks system for request lifecycle events
- Five hook types: `before_request`, `after_request`, `on_response`, `on_error`, `around_request`
- Global and per-client hook registration
- `Zenrows::Hooks::LogSubscriber` built-in logging subscriber
- `InstrumentedClient` wrapper for HTTP client instrumentation
- Context object with ZenRows header parsing (request_cost, concurrency_remaining, request_id, final_url)
- RBS type signatures for all hooks classes
- Monotonic clock for accurate request duration timing

### Changed

- `after_request` hook now always runs (via `ensure`), even on errors

## [0.2.1] - 2025-12-25

### Added

- Configurable `api_endpoint` for ApiClient (global config or per-instance)
- `net_http` backend as fallback when http.rb unavailable
- GitHub Pages for YARD documentation

### Changed

- SSL context now auto-configured in proxy client (no need to pass `ssl_context:` on every request)

## [0.2.0] - 2025-12-25

### Added

- `ApiClient` for REST API mode (autoparse, css_extractor, markdown output)
- `CssExtractor` DSL for building extraction rules
- `ApiResponse` wrapper with typed accessors
- Proxy options: `device`, `antibot`, `session_ttl`
- RBS type signatures
- rubocop-minitest linting
- Dependabot configuration

### Changed

- Require Ruby >= 3.2.0

## [0.1.0] - 2025-12-25

### Added

- Initial release
- Multi-backend architecture with http.rb as primary adapter
- Proxy mode support (ZenRows superproxy)
- JavaScript rendering support
- Premium proxy and geolocation options
- JavaScript Instructions DSL for browser automation
- Screenshot support (full page and element)
- Session persistence
- Block resources option
- Wait and wait_for parameters
- Custom headers support
- YARD documentation
- Minitest test suite
- Standard RB linting
- Optional Rails integration with ActiveSupport::Duration support
