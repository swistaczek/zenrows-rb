# CLAUDE.md

Ruby gem for ZenRows web scraping proxy. Multi-backend HTTP client (http.rb primary).

## Context7 MCP

Use Context7 for docs lookup:
- `/websites/guides_rubygems` - RubyGems packaging
- `/docs.zenrows.com-4bed007/llmstxt` - ZenRows API
- `/websites/code_claude_en` - Claude Code CLI

## Commands

```bash
bundle install          # Install dependencies
bundle exec rake test   # Run tests
bundle exec rubocop     # Lint code
bundle exec yard doc    # Generate docs
bundle exec rake build  # Build gem
```

## Architecture

```
lib/zenrows/
├── version.rb           # Gem version
├── configuration.rb     # Global config (api_key, host, port)
├── client.rb            # Main client, returns HTTP instances
├── proxy.rb             # Proxy URL builder (options in username)
├── js_instructions.rb   # DSL for browser automation
├── errors.rb            # Custom exceptions
├── railtie.rb           # Optional Rails integration
└── backends/
    ├── base.rb          # Backend interface
    └── http_rb.rb       # http.rb adapter (primary)
```

## Usage

```ruby
Zenrows.configure do |c|
  c.api_key = 'YOUR_KEY'
  c.host = 'superproxy.zenrows.com'
  c.port = 1337
end

client = Zenrows::Client.new
http = client.http(js_render: true, premium_proxy: true)
response = http.get('https://example.com')  # SSL verification disabled for proxy
```

## Key Options

| Option | Type | Description |
|--------|------|-------------|
| `js_render` | Boolean | Enable headless browser |
| `premium_proxy` | Boolean | Use residential IPs |
| `proxy_country` | String | Country code (us, gb, de) |
| `wait` | Integer | Wait time in ms |
| `wait_for` | String | CSS selector to wait for |
| `js_instructions` | Array/JSON | Browser automation |
| `session_id` | Bool/String | Sticky session |
| `screenshot` | Boolean | Take screenshot |
