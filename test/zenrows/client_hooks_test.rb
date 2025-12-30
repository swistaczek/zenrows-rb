# frozen_string_literal: true

require "test_helper"

class ClientHooksTest < Minitest::Test
  def setup
    Zenrows.reset_configuration!
    Zenrows.configure do |c|
      c.api_key = "test_api_key"
    end
  end

  def teardown
    Zenrows.reset_configuration!
  end

  def test_client_inherits_global_hooks
    global_called = false
    Zenrows.configure do |c|
      c.on_response { global_called = true }
    end

    client = Zenrows::Client.new
    refute client.hooks.empty?
  end

  def test_client_with_per_client_hooks
    client = Zenrows::Client.new do |c|
      c.on_response { }
    end

    refute client.hooks.empty?
  end

  def test_per_client_hooks_dont_modify_global
    global_empty_before = Zenrows.configuration.hooks.empty?

    Zenrows.configure do |c|
      c.on_response { }
    end

    global_not_empty = !Zenrows.configuration.hooks.empty?

    client = Zenrows::Client.new do |c|
      c.on_error { }
    end

    # Global hooks should still have same state
    global_still_not_empty = !Zenrows.configuration.hooks.empty?

    assert global_empty_before
    assert global_not_empty
    assert global_still_not_empty
    refute client.hooks.empty?
  end

  def test_multiple_clients_have_independent_hooks
    client1 = Zenrows::Client.new do |c|
      c.on_response { :client1 }
    end

    client2 = Zenrows::Client.new do |c|
      c.on_error { :client2 }
    end

    # Each client should have its own hooks instance
    refute_same client1.hooks, client2.hooks
  end

  def test_http_returns_instrumented_client_when_hooks_present
    client = Zenrows::Client.new do |c|
      c.on_response { }
    end

    http = client.http(js_render: true)

    assert_instance_of Zenrows::InstrumentedClient, http
  end

  def test_http_returns_raw_client_when_no_hooks
    # Reset to ensure no global hooks
    Zenrows.reset_configuration!
    Zenrows.configure { |c| c.api_key = "test" }

    client = Zenrows::Client.new
    http = client.http(js_render: true)

    assert_instance_of HTTP::Client, http
  end

  def test_per_client_hook_configurator_methods
    # Test all DSL methods are available
    client = Zenrows::Client.new do |c|
      c.before_request { }
      c.after_request { }
      c.on_response { }
      c.on_error { }
      c.around_request { |ctx, &block| block.call }
      c.add_subscriber(Object.new)
    end

    refute client.hooks.empty?
  end
end
