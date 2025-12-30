# frozen_string_literal: true

require "test_helper"

class HooksTest < Minitest::Test
  def setup
    @hooks = Zenrows::Hooks.new
  end

  def test_register_with_block
    called = false
    @hooks.register(:on_response) { called = true }

    @hooks.run(:on_response, nil, {})

    assert called
  end

  def test_register_with_callable
    called = false
    callable = ->(resp, ctx) { called = true }
    @hooks.register(:on_response, callable)

    @hooks.run(:on_response, nil, {})

    assert called
  end

  def test_register_raises_on_invalid_event
    assert_raises ArgumentError do
      @hooks.register(:invalid_event) {}
    end
  end

  def test_register_raises_without_handler
    assert_raises ArgumentError do
      @hooks.register(:on_response)
    end
  end

  def test_register_raises_on_non_callable
    assert_raises ArgumentError do
      @hooks.register(:on_response, "not callable")
    end
  end

  def test_multiple_callbacks_for_same_event
    results = []
    @hooks.register(:on_response) { results << 1 }
    @hooks.register(:on_response) { results << 2 }

    @hooks.run(:on_response, nil, {})

    assert_equal [1, 2], results
  end

  def test_add_subscriber
    subscriber = Object.new
    def subscriber.on_response(resp, ctx)
      @called = true
    end

    def subscriber.called?
      @called
    end

    @hooks.add_subscriber(subscriber)
    @hooks.run(:on_response, nil, {})

    assert_predicate subscriber, :called?
  end

  def test_subscriber_with_multiple_methods
    subscriber = Object.new
    subscriber.instance_variable_set(:@calls, [])
    def subscriber.before_request(ctx)
      @calls << :before
    end

    def subscriber.on_response(resp, ctx)
      @calls << :response
    end

    def subscriber.calls
      @calls
    end

    @hooks.add_subscriber(subscriber)
    @hooks.run(:before_request, {})
    @hooks.run(:on_response, nil, {})

    assert_equal [:before, :response], subscriber.calls
  end

  def test_empty_when_no_hooks
    assert_empty @hooks
  end

  def test_not_empty_after_register
    @hooks.register(:on_response) {}

    refute_empty @hooks
  end

  def test_not_empty_after_add_subscriber
    @hooks.add_subscriber(Object.new)

    refute_empty @hooks
  end

  def test_dup_creates_independent_copy
    @hooks.register(:on_response) {}

    copy = @hooks.dup
    copy.register(:on_error) {}

    # Original should not have on_error
    refute_empty @hooks
    refute_empty copy
  end

  def test_merge_combines_hooks
    other = Zenrows::Hooks.new
    results = []

    @hooks.register(:on_response) { results << 1 }
    other.register(:on_response) { results << 2 }

    @hooks.merge(other)
    @hooks.run(:on_response, nil, {})

    assert_equal [1, 2], results
  end

  def test_merge_with_nil_is_noop
    @hooks.register(:on_response) {}
    @hooks.merge(nil)

    refute_empty @hooks
  end

  def test_around_request_wraps_block
    order = []

    @hooks.register(:around_request) do |ctx, &block|
      order << :before
      result = block.call
      order << :after
      result
    end

    result = @hooks.run_around({}) do
      order << :inside
      :result
    end

    assert_equal [:before, :inside, :after], order
    assert_equal :result, result
  end

  def test_multiple_around_hooks_chain
    order = []

    @hooks.register(:around_request) do |ctx, &block|
      order << :outer_before
      result = block.call
      order << :outer_after
      result
    end

    @hooks.register(:around_request) do |ctx, &block|
      order << :inner_before
      result = block.call
      order << :inner_after
      result
    end

    @hooks.run_around({}) do
      order << :core
      :result
    end

    assert_equal [:outer_before, :inner_before, :core, :inner_after, :outer_after], order
  end

  def test_run_around_without_hooks
    result = @hooks.run_around({}) { :result }

    assert_equal :result, result
  end

  def test_valid_events
    assert_equal [:before_request, :after_request, :on_response, :on_error, :around_request],
      Zenrows::Hooks::EVENTS
  end

  def test_run_passes_arguments_to_callbacks
    received_args = nil
    @hooks.register(:on_response) { |resp, ctx| received_args = [resp, ctx] }

    @hooks.run(:on_response, :response, {key: :value})

    assert_equal [:response, {key: :value}], received_args
  end

  def test_returns_self_for_chaining
    result = @hooks.register(:on_response) {}

    assert_same @hooks, result

    result = @hooks.add_subscriber(Object.new)

    assert_same @hooks, result
  end
end
