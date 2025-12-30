# frozen_string_literal: true

require "test_helper"

class ConfigurationHooksTest < Minitest::Test
  def setup
    Zenrows.reset_configuration!
  end

  def teardown
    Zenrows.reset_configuration!
  end

  def test_configuration_has_hooks
    assert_instance_of Zenrows::Hooks, Zenrows.configuration.hooks
  end

  def test_on_response_registers_hook
    called = false
    Zenrows.configure do |c|
      c.api_key = "test"
      c.on_response { called = true }
    end

    refute_empty Zenrows.configuration.hooks
  end

  def test_on_error_registers_hook
    called = false
    Zenrows.configure do |c|
      c.api_key = "test"
      c.on_error { called = true }
    end

    refute_empty Zenrows.configuration.hooks
  end

  def test_before_request_registers_hook
    Zenrows.configure do |c|
      c.api_key = "test"
      c.before_request {}
    end

    refute_empty Zenrows.configuration.hooks
  end

  def test_after_request_registers_hook
    Zenrows.configure do |c|
      c.api_key = "test"
      c.after_request {}
    end

    refute_empty Zenrows.configuration.hooks
  end

  def test_around_request_registers_hook
    Zenrows.configure do |c|
      c.api_key = "test"
      c.around_request { |ctx, &block| block.call }
    end

    refute_empty Zenrows.configuration.hooks
  end

  def test_add_subscriber_registers_subscriber
    subscriber = Object.new
    def subscriber.on_response(resp, ctx)
    end

    Zenrows.configure do |c|
      c.api_key = "test"
      c.add_subscriber(subscriber)
    end

    refute_empty Zenrows.configuration.hooks
  end

  def test_reset_clears_hooks
    Zenrows.configure do |c|
      c.api_key = "test"
      c.on_response {}
    end

    refute_empty Zenrows.configuration.hooks

    Zenrows.reset_configuration!

    assert_empty Zenrows.configuration.hooks
  end

  def test_hook_methods_return_self_for_chaining
    Zenrows.configure do |c|
      result = c.on_response {}
        .on_error {}
        .before_request {}
        .after_request {}

      assert_equal c, result
    end
  end
end
