# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class ApiClientTest < Minitest::Test
  def setup
    Zenrows.configure do |config|
      config.api_key = "test_api_key"
    end
    @client = Zenrows::ApiClient.new
  end

  def teardown
    Zenrows.reset_configuration!
    WebMock.reset!
  end

  def test_initialization_with_global_config
    assert_equal "test_api_key", @client.api_key
  end

  def test_initialization_with_custom_api_key
    client = Zenrows::ApiClient.new(api_key: "custom_key")

    assert_equal "custom_key", client.api_key
  end

  def test_get_basic_request
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(apikey: "test_api_key", url: "https://example.com"))
      .to_return(status: 200, body: "<html>Test</html>")

    response = @client.get("https://example.com")

    assert_equal 200, response.status
    assert_equal "<html>Test</html>", response.html
  end

  def test_get_with_autoparse
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(autoparse: "true"))
      .to_return(status: 200, body: '{"title":"Product"}')

    response = @client.get("https://amazon.com/dp/123", autoparse: true)

    assert_equal "Product", response.parsed["title"]
  end

  def test_get_with_css_extractor_hash
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(css_extractor: '{"title":"h1"}'))
      .to_return(status: 200, body: '{"title":"Page Title"}')

    response = @client.get("https://example.com", css_extractor: {title: "h1"})

    assert_equal "Page Title", response.extracted["title"]
  end

  def test_get_with_css_extractor_dsl
    extractor = Zenrows::CssExtractor.build do
      extract :title, "h1"
      links :urls, "a"
    end

    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(css_extractor: '{"title":"h1","urls":"a @href"}'))
      .to_return(status: 200, body: '{"title":"Test","urls":["link1"]}')

    response = @client.get("https://example.com", css_extractor: extractor)

    assert_equal "Test", response.extracted["title"]
  end

  def test_get_with_markdown_response
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(response_type: "markdown"))
      .to_return(status: 200, body: "# Title\n\nText")

    response = @client.get("https://example.com", response_type: "markdown")

    assert_equal "# Title\n\nText", response.markdown
  end

  def test_get_with_js_render
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(js_render: "true"))
      .to_return(status: 200, body: "<html>Rendered</html>")

    response = @client.get("https://example.com", js_render: true)

    assert_equal "<html>Rendered</html>", response.html
  end

  def test_get_with_premium_proxy
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(premium_proxy: "true", proxy_country: "us"))
      .to_return(status: 200, body: "OK")

    response = @client.get("https://example.com", premium_proxy: true, proxy_country: "us")

    assert_predicate response, :success?
  end

  def test_get_with_antibot
    stub_request(:get, "https://api.zenrows.com/v1/")
      .with(query: hash_including(antibot: "true"))
      .to_return(status: 200, body: "OK")

    response = @client.get("https://example.com", antibot: true)

    assert_predicate response, :success?
  end

  def test_authentication_error
    stub_request(:get, /api\.zenrows\.com/)
      .with(query: hash_including(apikey: "test_api_key"))
      .to_return(status: 401, body: "Unauthorized")

    assert_raises Zenrows::AuthenticationError do
      @client.get("https://example.com")
    end
  end

  def test_rate_limit_error
    stub_request(:get, /api\.zenrows\.com/)
      .with(query: hash_including(apikey: "test_api_key"))
      .to_return(status: 429, body: "Too Many Requests", headers: {"Retry-After" => "60"})

    error = assert_raises Zenrows::RateLimitError do
      @client.get("https://example.com")
    end

    assert_equal 60, error.retry_after
  end

  def test_bot_detected_error
    stub_request(:get, /api\.zenrows\.com/)
      .with(query: hash_including(apikey: "test_api_key"))
      .to_return(status: 403, body: "Bot detected")

    error = assert_raises Zenrows::BotDetectedError do
      @client.get("https://example.com")
    end

    assert_includes error.suggestion, "premium_proxy"
  end

  def test_post_request
    stub_request(:post, "https://api.zenrows.com/v1/")
      .with(
        query: hash_including(apikey: "test_api_key", url: "https://example.com"),
        body: "form_data=value"
      )
      .to_return(status: 200, body: "Posted")

    response = @client.post("https://example.com", body: "form_data=value")

    assert_predicate response, :success?
  end
end
