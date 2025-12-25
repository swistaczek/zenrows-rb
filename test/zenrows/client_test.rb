# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    Zenrows.reset_configuration!
    Zenrows.configure do |config|
      config.api_key = "test_api_key"
    end
  end

  def test_initialize_with_global_config
    client = Zenrows::Client.new

    assert_equal "test_api_key", client.config.api_key
    assert_equal "superproxy.zenrows.com", client.config.host
    assert_equal 1337, client.config.port
  end

  def test_initialize_with_overrides
    client = Zenrows::Client.new(
      api_key: "override_key",
      host: "custom.proxy.com",
      port: 8080
    )

    assert_equal "override_key", client.config.api_key
    assert_equal "custom.proxy.com", client.config.host
    assert_equal 8080, client.config.port
  end

  def test_initialize_raises_without_api_key
    Zenrows.reset_configuration!

    assert_raises Zenrows::ConfigurationError do
      Zenrows::Client.new
    end
  end

  def test_http_returns_http_client
    client = Zenrows::Client.new
    http = client.http(js_render: true)

    assert_kind_of HTTP::Client, http
  end

  def test_ssl_context
    client = Zenrows::Client.new
    ssl = client.ssl_context

    assert_kind_of OpenSSL::SSL::SSLContext, ssl
    assert_equal OpenSSL::SSL::VERIFY_NONE, ssl.verify_mode
  end

  def test_proxy_config
    client = Zenrows::Client.new
    config = client.proxy_config(js_render: true, premium_proxy: true)

    assert_equal "superproxy.zenrows.com", config[:host]
    assert_equal 1337, config[:port]
    assert_equal "test_api_key", config[:username]
    assert_includes config[:password], "js_render=true"
    assert_includes config[:password], "premium_proxy=true"
  end

  def test_proxy_url
    client = Zenrows::Client.new
    url = client.proxy_url(js_render: true)

    assert_includes url, "test_api_key"
    assert_includes url, "superproxy.zenrows.com"
    assert_includes url, "js_render=true"
  end

  def test_unsupported_backend_raises
    Zenrows.configure { |c| c.backend = :unsupported }

    assert_raises Zenrows::ConfigurationError do
      Zenrows::Client.new
    end
  end
end
