# frozen_string_literal: true

require "test_helper"

class ProxyTest < Minitest::Test
  def setup
    @proxy = Zenrows::Proxy.new(
      api_key: "test_api_key",
      host: "superproxy.zenrows.com",
      port: 1337
    )
  end

  def test_build_basic_config
    config = @proxy.build

    assert_equal "superproxy.zenrows.com", config[:host]
    assert_equal 1337, config[:port]
    assert_equal "test_api_key", config[:username]
    assert_equal "", config[:password]
  end

  def test_build_with_js_render
    config = @proxy.build(js_render: true)

    assert_includes config[:password], "js_render=true"
  end

  def test_build_with_premium_proxy
    config = @proxy.build(premium_proxy: true)

    assert_includes config[:password], "premium_proxy=true"
  end

  def test_build_with_proxy_country_enables_premium
    config = @proxy.build(proxy_country: "us")

    assert_includes config[:password], "proxy_country=us"
    assert_includes config[:password], "premium_proxy=true"
  end

  def test_build_with_wait_boolean
    config = @proxy.build(wait: true)

    assert_includes config[:password], "wait=15000"
    assert_includes config[:password], "js_render=true"
  end

  def test_build_with_wait_integer
    config = @proxy.build(wait: 5000)

    assert_includes config[:password], "wait=5000"
  end

  def test_build_with_wait_for_selector
    config = @proxy.build(wait_for: ".content")

    assert_includes config[:password], "wait_for=.content"
    assert_includes config[:password], "js_render=true"
  end

  def test_build_with_session_id_true
    config = @proxy.build(session_id: true)

    assert_match(/session_id=\d+/, config[:password])
  end

  def test_build_with_session_id_string
    config = @proxy.build(session_id: "my_session")

    assert_includes config[:password], "session_id=my_session"
  end

  def test_build_with_screenshot
    config = @proxy.build(screenshot: true)

    assert_includes config[:password], "screenshot=true"
    assert_includes config[:password], "js_render=true"
  end

  def test_build_with_json_response
    config = @proxy.build(json_response: true)

    assert_includes config[:password], "json_response=true"
    assert_includes config[:password], "js_render=true"
  end

  def test_build_with_block_resources
    config = @proxy.build(block_resources: "image,media,font")

    assert_includes config[:password], "block_resources=image,media,font"
  end

  def test_build_url
    url = @proxy.build_url(js_render: true)

    assert_equal "http://test_api_key:js_render=true@superproxy.zenrows.com:1337", url
  end

  def test_build_array
    arr = @proxy.build_array(js_render: true)

    assert_equal "superproxy.zenrows.com", arr[0]
    assert_equal 1337, arr[1]
    assert_equal "test_api_key", arr[2]
    assert_includes arr[3], "js_render=true"
  end

  def test_raises_on_excessive_wait_time
    assert_raises Zenrows::WaitTimeError do
      @proxy.build(wait: 200_000)
    end
  end

  def test_build_with_device_mobile
    config = @proxy.build(device: "mobile")

    assert_includes config[:password], "device=mobile"
  end

  def test_build_with_device_desktop
    config = @proxy.build(device: :desktop)

    assert_includes config[:password], "device=desktop"
  end

  def test_build_with_antibot
    config = @proxy.build(antibot: true)

    assert_includes config[:password], "antibot=true"
  end

  def test_build_with_session_ttl
    config = @proxy.build(session_id: true, session_ttl: "30m")

    assert_includes config[:password], "session_ttl=30m"
    assert_match(/session_id=\d+/, config[:password])
  end

  def test_build_with_all_valid_session_ttl_values
    %w[30s 5m 30m 1h 1d].each do |ttl|
      config = @proxy.build(session_ttl: ttl)

      assert_includes config[:password], "session_ttl=#{ttl}"
    end
  end

  def test_raises_on_invalid_session_ttl
    assert_raises ArgumentError do
      @proxy.build(session_ttl: "invalid")
    end
  end
end
