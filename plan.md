# ZenRows Ruby Gem Extraction - Research & Plan

## Executive Summary

Extract ZenRows HTTP client from Marmot into standalone Ruby gem with multi-backend support (http.rb primary), comprehensive YARD docs, and feature parity with ZenRows API.

## Decisions

| Decision | Choice |
|----------|--------|
| Gem name | `zenrows` |
| Repository | Separate repo (new standalone) |
| Primary mode | Proxy mode (current impl) |
| Credits API | Dashboard only (no public API exists) |
| Rails support | Optional (ActiveSupport::Duration) |
| License | MIT |

---

## Current Implementation Analysis

### Source Files (Marmot)
| File | Lines | Purpose |
|------|-------|---------|
| `app/helpers/zenrows_helper.rb` | 286 | HTTP client factory, proxy config, SSL, DNS caching |
| `lib/cli/zenrows_cli.rb` | 1632 | CLI tool (not part of gem) |
| `lib/cli/dom_simplifier.rb` | 1484 | HTML processing (not part of gem) |
| `lib/cli/file_cache.rb` | 121 | Caching (not part of gem) |

### Current Features in `ZenrowsHelper`
```ruby
zenrows_http_client(opts = {})
  # Connection
  :connect_timeout    # default 5s
  :read_timeout       # default 180s (auto-calc with js_render)

  # JavaScript Rendering
  :js_render          # boolean - headless browser
  :wait               # int/duration - wait time (ms or ActiveSupport::Duration)
  :js_instructions    # JSON array - browser automation
  :json_response      # boolean - get JSON instead of HTML
  :screenshot         # boolean - take screenshot
  :screenshot_fullpage # boolean
  :screenshot_selector # CSS selector

  # Proxy
  :premium_proxy      # boolean - residential IPs
  :proxy_country      # string - country code (enables premium)
  :session_id         # bool/string - session persistence

  # Browser
  :window_height      # int
  :window_width       # int

  # Headers
  :headers            # Hash
  :custom_headers     # boolean - enable custom headers
  :original_status    # boolean - return original HTTP status

# Helper methods
zenrows_ssl_context              # SSL context (verify_mode: NONE)
http_zenrows_proxy_url(opts)     # Build proxy URL
http_zenrows_proxy_array(opts)   # [host, port, user, pass]
wss_zenrows_proxy_url(opts)      # WebSocket proxy URL
ensure_dns_resolved(url, opts)   # DNS pre-resolution with caching
```

---

## ZenRows API Feature Comparison

### API Parameters (from ZenRows docs)
| Parameter | Current | Notes |
|-----------|---------|-------|
| `js_render` | ✅ | Headless browser |
| `premium_proxy` | ✅ | Residential IPs |
| `proxy_country` | ✅ | Geolocation |
| `wait` | ✅ | Wait after load (ms) |
| `wait_for` | ❌ MISSING | Wait for CSS selector |
| `js_instructions` | ✅ | Browser automation |
| `json_response` | ✅ | JSON output |
| `screenshot` | ✅ | Page screenshot |
| `screenshot_fullpage` | ✅ | Full page screenshot |
| `screenshot_selector` | ✅ | Element screenshot |
| `custom_headers` | ✅ | Custom HTTP headers |
| `session_id` | ✅ | Session persistence |
| `block_resources` | ❌ MISSING | Block CSS/images/fonts |
| `original_status` | ✅ | Original HTTP status |
| `window_width/height` | ✅ | Browser dimensions |
| `autoparse` | ❌ MISSING | Auto-extract data |
| `css_extractor` | ❌ MISSING | CSS-based extraction |
| `markdown_response` | ❌ MISSING | Markdown output |

### JavaScript Instructions (all supported in current impl)
- `wait` - Wait duration
- `wait_for` - Wait for selector
- `wait_event` - networkidle/load/domcontentloaded
- `click` - Click element
- `fill` - Fill input
- `check`/`uncheck` - Checkboxes
- `select_option` - Dropdowns
- `scroll_y`/`scroll_x` - Scrolling
- `scroll_to` - bottom/top
- `evaluate` - Custom JS
- `frame_*` - Iframe interactions
- `solve_captcha` - reCAPTCHA solving

---

## Gem Architecture Design

### Directory Structure
```
zenrows-rb/
├── lib/
│   ├── zenrows.rb              # Main entry, configuration
│   ├── zenrows/
│   │   ├── version.rb
│   │   ├── configuration.rb    # Global config (api_key, defaults)
│   │   ├── client.rb           # Main client class
│   │   ├── request.rb          # Request builder
│   │   ├── response.rb         # Response wrapper
│   │   ├── errors.rb           # Custom exceptions
│   │   ├── proxy.rb            # Proxy URL builder
│   │   ├── js_instructions.rb  # JS instruction builder (DSL)
│   │   └── backends/
│   │       ├── base.rb         # Backend interface
│   │       ├── http_rb.rb      # http.rb adapter (primary)
│   │       ├── faraday.rb      # Faraday adapter (future)
│   │       └── net_http.rb     # Net::HTTP adapter (future)
├── sig/                        # RBS type signatures
├── spec/                       # RSpec tests
├── .yardopts
├── zenrows.gemspec
├── Gemfile
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### Multi-Backend Architecture
```ruby
module Zenrows
  module Backends
    class Base
      def get(url, options = {})
        raise NotImplementedError
      end

      def post(url, body, options = {})
        raise NotImplementedError
      end
    end

    class HttpRb < Base
      # Primary backend using http.rb gem
      # Supports: proxy, ssl_context, timeouts, headers
    end
  end
end
```

### Public API Design
```ruby
# Configuration
Zenrows.configure do |config|
  config.api_key = 'YOUR_API_KEY'
  config.host = 'superproxy.zenrows.com'  # from credentials
  config.port = 1337
  config.default_timeout = 180
  config.backend = :http_rb  # :faraday, :net_http (future)
end

# Get pre-configured HTTP client (proxy mode)
client = Zenrows::Client.new

# Simple proxy client
http = client.http(js_render: true, premium_proxy: true)
response = http.get('https://example.com')

# With full options
http = client.http(
  js_render: true,
  premium_proxy: true,
  proxy_country: 'us',
  wait: 5000,                # ms or ActiveSupport::Duration
  wait_for: '.content',      # CSS selector
  session_id: true           # sticky session
)
response = http.get(url)

# Response handling
response.body          # HTML string
response.status        # HTTP status
response.headers       # Response headers (includes Zr-* headers)
response.final_url     # From Zr-Final-Url header
response.cookies       # From Zr-Cookies header

# JS Instructions DSL (optional)
instructions = Zenrows::JsInstructions.build do
  click '.load-more'
  wait 2000
  fill 'input#email', 'test@example.com'
  scroll_to :bottom
  wait_for '.results'
end
http = client.http(js_render: true, js_instructions: instructions)

# SSL context (auto-configured, verify_mode: NONE for proxy)
# Timeouts auto-calculated based on js_render + wait options
```

---

## http.rb Backend Implementation

### Key Patterns from http.rb docs
```ruby
# Proxy with auth
HTTP.via("proxy-hostname", 8080, "username", "password")
  .get("http://example.com")

# Custom proxy headers
HTTP.via("proxy-hostname", 8080, {"Proxy-Authorization" => "..."})
  .get("http://example.com")

# Timeouts (per-operation)
HTTP.timeout(connect: 5, write: 2, read: 10).get(url)

# Global timeout
HTTP.timeout(30).get(url)

# SSL context
ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
HTTP.get(url, ssl_context: ssl_context)

# Headers
HTTP.headers("User-Agent" => "...", "Accept" => "...").get(url)
```

---

## YARD Documentation Standards

### Required Tags
```ruby
# @author Ernest Surudo
# @since 1.0.0
# @api public

# @param url [String] Target URL to scrape
# @param options [Hash] Request options
# @option options [Boolean] :js_render Enable JavaScript rendering
# @option options [Boolean] :premium_proxy Use residential proxies
# @option options [String] :proxy_country ISO country code (us, gb, de)
# @option options [Integer] :wait Wait time in milliseconds
# @option options [String] :wait_for CSS selector to wait for
# @return [Zenrows::Response] Response object
# @raise [Zenrows::Error] Base error class
# @raise [Zenrows::RateLimitError] When rate limited (429)
# @raise [Zenrows::AuthenticationError] Invalid API key
# @example Basic request
#   client.get('https://example.com')
# @example With JavaScript rendering
#   client.get('https://example.com', js_render: true, wait: 5000)
def get(url, options = {})
end
```

---

## Implementation Plan

### Phase 1: Gem Skeleton
```bash
bundle gem zenrows --test=rspec --ci=github --linter=rubocop
```
- Configure gemspec (http dependency, MIT license)
- Set up YARD (.yardopts)
- Configure RuboCop with relaxed rules

### Phase 2: Configuration Module
```ruby
# lib/zenrows.rb
# lib/zenrows/configuration.rb
```
- Global config: api_key, host, port, default_timeout, backend
- Thread-safe configuration
- Optional Rails initializer generator

### Phase 3: Backend Interface + http.rb Adapter
```ruby
# lib/zenrows/backends/base.rb
# lib/zenrows/backends/http_rb.rb
```
- Abstract base with `#build_client(options)` method
- http.rb implementation with proxy, SSL, timeouts
- Port logic from `zenrows_helper.rb:30-200`

### Phase 4: Proxy URL Builder
```ruby
# lib/zenrows/proxy.rb
```
- Build proxy URL with options encoded in username
- Format: `http://API_KEY-opt1-val1-opt2-val2:@host:port`
- Support all ZenRows proxy options

### Phase 5: Client Class
```ruby
# lib/zenrows/client.rb
```
- `#http(options)` returns configured HTTP client
- Timeout auto-calculation (base + js_render + wait)
- SSL context configuration

### Phase 6: JS Instructions DSL
```ruby
# lib/zenrows/js_instructions.rb
```
- Builder pattern with block syntax
- All instructions: click, fill, wait, scroll, evaluate, frame_*
- JSON serialization for proxy header

### Phase 7: Response Enhancement (optional)
```ruby
# lib/zenrows/response.rb  # Only if wrapping needed
```
- Helper methods for Zr-* headers
- Cookie extraction
- Final URL extraction

### Phase 8: Error Classes
```ruby
# lib/zenrows/errors.rb
```
- `Zenrows::Error` base class
- Specific errors with helpful messages
- Retry suggestions

### Phase 9: Rails Integration (optional)
```ruby
# lib/zenrows/railtie.rb
# lib/generators/zenrows/install_generator.rb
```
- ActiveSupport::Duration support in wait option
- Rails config generator (optional)

### Phase 10: Documentation & Testing
- YARD docs for all public methods
- RSpec unit tests with WebMock
- VCR for integration tests
- README with comprehensive examples
- CHANGELOG

---

## Missing Features to Add

| Feature | Priority | Notes |
|---------|----------|-------|
| `wait_for` | HIGH | Wait for CSS selector |
| `block_resources` | MEDIUM | Block images/fonts/CSS |
| `autoparse` | LOW | Auto-extraction |
| `css_extractor` | LOW | CSS-based extraction |
| `markdown_response` | LOW | Markdown output |

---

## Files to Extract/Reference

### From Marmot (copy logic, rewrite for gem)
- `app/helpers/zenrows_helper.rb:30-100` - Proxy URL building
- `app/helpers/zenrows_helper.rb:100-200` - HTTP client configuration
- `app/helpers/zenrows_helper.rb:200-286` - DNS resolution, SSL context

### Dependencies
```ruby
# zenrows.gemspec
spec.add_dependency 'http', '~> 5.0'        # Primary HTTP backend
spec.add_dependency 'addressable', '~> 2.8' # URL handling

spec.add_development_dependency 'rspec', '~> 3.12'
spec.add_development_dependency 'vcr', '~> 6.0'
spec.add_development_dependency 'webmock', '~> 3.0'
spec.add_development_dependency 'yard', '~> 0.9'
spec.add_development_dependency 'rubocop', '~> 1.0'
```

---

## Final File Structure

```
zenrows/
├── lib/
│   ├── zenrows.rb                    # Main entry point
│   └── zenrows/
│       ├── version.rb
│       ├── configuration.rb
│       ├── client.rb
│       ├── proxy.rb
│       ├── js_instructions.rb
│       ├── errors.rb
│       ├── railtie.rb               # Optional Rails
│       └── backends/
│           ├── base.rb
│           └── http_rb.rb           # Primary backend
├── sig/                              # RBS types (future)
├── spec/
│   ├── zenrows/
│   │   ├── client_spec.rb
│   │   ├── proxy_spec.rb
│   │   └── js_instructions_spec.rb
│   ├── spec_helper.rb
│   └── fixtures/vcr_cassettes/
├── .yardopts
├── .rubocop.yml
├── zenrows.gemspec
├── Gemfile
├── Rakefile
├── README.md
├── CHANGELOG.md
└── LICENSE.txt
```

## Source Reference

Extract core logic from Marmot file:
- **`app/helpers/zenrows_helper.rb`** - All proxy/client building logic
