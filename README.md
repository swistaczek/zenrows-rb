# Zenrows

Ruby client for [ZenRows](https://www.zenrows.com/) web scraping proxy. Multi-backend HTTP client with http.rb as primary adapter.

## Installation

Add to your Gemfile:

```ruby
gem 'zenrows'
```

Then run:

```bash
bundle install
```

## Configuration

```ruby
Zenrows.configure do |config|
  config.api_key = 'YOUR_API_KEY'
  config.host = 'superproxy.zenrows.com'  # default
  config.port = 1337                       # default
  config.connect_timeout = 5               # seconds
  config.read_timeout = 180                # seconds
end
```

## Usage

### Basic Request

```ruby
client = Zenrows::Client.new
http = client.http(js_render: true, premium_proxy: true)
response = http.get('https://example.com', ssl_context: client.ssl_context)

puts response.body
puts response.status
```

### With Options

```ruby
http = client.http(
  js_render: true,           # Enable headless browser
  premium_proxy: true,       # Use residential IPs
  proxy_country: 'us',       # Geolocation
  wait: 5000,                # Wait 5 seconds after load
  wait_for: '.content',      # Wait for CSS selector
  session_id: true           # Sticky session
)
```

### JavaScript Instructions

Automate browser interactions:

```ruby
instructions = Zenrows::JsInstructions.build do
  wait_for '.login-form'
  fill '#email', 'user@example.com'
  fill '#password', 'secret123'
  click '#submit'
  wait 2000
  scroll_to :bottom
  wait_for '.results'
end

http = client.http(js_render: true, js_instructions: instructions)
response = http.get(url, ssl_context: client.ssl_context)
```

Available instructions:

- `click(selector)` - Click element
- `wait(ms)` - Wait duration
- `wait_for(selector)` - Wait for element
- `wait_event(event)` - networkidle, load, domcontentloaded
- `fill(selector, value)` - Fill input
- `check(selector)` / `uncheck(selector)` - Checkboxes
- `select_option(selector, value)` - Dropdowns
- `scroll_y(pixels)` / `scroll_x(pixels)` - Scroll
- `scroll_to(:bottom)` / `scroll_to(:top)` - Scroll to position
- `evaluate(js_code)` - Execute JavaScript
- `frame_*` variants for iframe interactions

### Screenshots

```ruby
http = client.http(
  js_render: true,
  screenshot: true,           # Take screenshot
  screenshot_fullpage: true,  # Full page
  json_response: true         # Get JSON with screenshot data
)
```

### Block Resources

Speed up requests by blocking unnecessary resources:

```ruby
http = client.http(
  js_render: true,
  block_resources: 'image,media,font'
)
```

### Device & Antibot

```ruby
http = client.http(
  js_render: true,
  device: 'mobile',      # mobile/desktop emulation
  antibot: true          # enhanced antibot bypass
)
```

## API Client (v0.2.0+)

For advanced extraction features, use the REST API client:

### Autoparse

Extract structured data from known sites (Amazon, etc.):

```ruby
api = Zenrows::ApiClient.new
response = api.get('https://amazon.com/dp/B01LD5GO7I', autoparse: true)

response.parsed  # => { "title" => "...", "price" => "$29.99", ... }
```

### CSS Extraction

Extract data using CSS selectors:

```ruby
# Hash syntax
response = api.get(url, css_extractor: {
  title: 'h1',
  links: 'a @href',
  prices: '.price'
})
response.extracted  # => { "title" => "...", "links" => [...], "prices" => [...] }

# DSL syntax
extractor = Zenrows::CssExtractor.build do
  extract :title, 'h1'
  links :urls, 'a.product'
  images :photos, 'img.gallery'
end
response = api.get(url, css_extractor: extractor)
```

### Markdown Output

```ruby
response = api.get(url, response_type: 'markdown')
response.markdown  # => "# Page Title\n\nContent..."
```

### Response Metadata

```ruby
response = api.get(url)
response.status              # => 200
response.success?            # => true
response.final_url           # => "https://example.com/redirected"
response.request_cost        # => 0.001
response.concurrency_remaining  # => 199
```

## Options Reference

| Option                | Type            | Description                        |
| --------------------- | --------------- | ---------------------------------- |
| `js_render`           | Boolean         | Enable JavaScript rendering        |
| `premium_proxy`       | Boolean         | Use residential proxies            |
| `proxy_country`       | String          | Country code (us, gb, de, etc.)    |
| `device`              | String          | Device emulation (mobile/desktop)  |
| `antibot`             | Boolean         | Enhanced antibot bypass            |
| `wait`                | Integer/Boolean | Wait time in ms (true = 15000)     |
| `wait_for`            | String          | CSS selector to wait for           |
| `session_id`          | Boolean/String  | Session persistence                |
| `session_ttl`         | String          | Session duration (1m, 10m, 30m)    |
| `window_height`       | Integer         | Browser window height              |
| `window_width`        | Integer         | Browser window width               |
| `js_instructions`     | Array/String    | Browser automation                 |
| `json_response`       | Boolean         | Return JSON instead of HTML        |
| `screenshot`          | Boolean         | Take screenshot                    |
| `screenshot_fullpage` | Boolean         | Full page screenshot               |
| `screenshot_selector` | String          | Screenshot specific element        |
| `block_resources`     | String          | Block resources (image,media,font) |
| `headers`             | Hash            | Custom HTTP headers                |

### API Client Options

| Option           | Type         | Description                          |
| ---------------- | ------------ | ------------------------------------ |
| `autoparse`      | Boolean      | Auto-extract structured data         |
| `css_extractor`  | Hash/Object  | CSS selectors for extraction         |
| `response_type`  | String       | Output format ('markdown')           |
| `outputs`        | String       | Extract specific data (headings,links) |

## Error Handling

```ruby
begin
  response = http.get(url, ssl_context: client.ssl_context)
rescue Zenrows::ConfigurationError => e
  # Missing or invalid configuration
rescue Zenrows::RateLimitError => e
  sleep(e.retry_after || 60)
  retry
rescue Zenrows::BotDetectedError => e
  # Try with premium proxy
  http = client.http(premium_proxy: true, proxy_country: 'us')
  retry
rescue Zenrows::WaitTimeError => e
  # Wait time exceeded 3 minutes
rescue Zenrows::TimeoutError => e
  # Request timed out
end
```

## Rails Integration

The gem automatically integrates with Rails when detected:

- Uses Rails.logger by default
- Supports ActiveSupport::Duration for wait times

```ruby
# In Rails, you can use duration objects
http = client.http(wait: 5.seconds)
```

## Development

```bash
bundle install
bundle exec rake test      # Run tests
bundle exec standardrb     # Lint code
bundle exec yard doc       # Generate docs
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
