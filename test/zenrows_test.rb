# frozen_string_literal: true

require "test_helper"

class ZenrowsTest < Minitest::Test
  def setup
    Zenrows.reset_configuration!
  end

  def test_that_it_has_a_version_number
    refute_nil Zenrows::VERSION
  end

  def test_configure_with_block
    Zenrows.configure do |config|
      config.api_key = "test_key"
      config.host = "proxy.example.com"
      config.port = 8080
    end

    assert_equal "test_key", Zenrows.configuration.api_key
    assert_equal "proxy.example.com", Zenrows.configuration.host
    assert_equal 8080, Zenrows.configuration.port
  end

  def test_default_configuration
    config = Zenrows.configuration

    assert_nil config.api_key
    assert_equal "superproxy.zenrows.com", config.host
    assert_equal 1337, config.port
    assert_equal 5, config.connect_timeout
    assert_equal 180, config.read_timeout
    assert_equal :http_rb, config.backend
  end

  def test_reset_configuration
    Zenrows.configure { |c| c.api_key = "test" }
    Zenrows.reset_configuration!

    assert_nil Zenrows.configuration.api_key
  end
end
