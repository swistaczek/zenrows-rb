# frozen_string_literal: true

require "test_helper"

class InstrumentedClientTest < Minitest::Test
  def setup
    @hooks = Zenrows::Hooks.new
    @mock_http = MockHttpClient.new
    @context_base = {options: {js_render: true}, backend: :http_rb}
  end

  def test_get_delegates_to_http_client
    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert_equal [[:get, "https://example.com", {}]], @mock_http.calls
  end

  def test_post_delegates_to_http_client
    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.post("https://example.com", body: "data")

    assert_equal [[:post, "https://example.com", {body: "data"}]], @mock_http.calls
  end

  def test_runs_before_request_hook
    before_called = false
    @hooks.register(:before_request) { |ctx| before_called = true }

    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert before_called
  end

  def test_runs_on_response_hook
    received_response = nil
    received_context = nil
    @hooks.register(:on_response) do |resp, ctx|
      received_response = resp
      received_context = ctx
    end

    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert_instance_of MockResponse, received_response
    assert_equal :get, received_context[:method]
    assert_equal "https://example.com", received_context[:url]
    assert_equal "example.com", received_context[:host]
  end

  def test_runs_after_request_hook
    after_called = false
    @hooks.register(:after_request) { |ctx| after_called = true }

    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert after_called
  end

  def test_runs_on_error_hook_and_reraises
    error = StandardError.new("Connection failed")
    received_error = nil
    received_context = nil

    @hooks.register(:on_error) do |err, ctx|
      received_error = err
      received_context = ctx
    end

    # Create a mock that raises
    error_http = Object.new
    error_http.define_singleton_method(:get) { |*| raise error }

    client = Zenrows::InstrumentedClient.new(error_http, hooks: @hooks, context_base: @context_base)

    raised = assert_raises StandardError do
      client.get("https://example.com")
    end

    assert_equal error, raised
    assert_equal error, received_error
    assert_equal "https://example.com", received_context[:url]
  end

  def test_runs_around_request_hook
    order = []

    @hooks.register(:around_request) do |ctx, &block|
      order << :before
      result = block.call
      order << :after
      result
    end

    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert_equal [:before, :after], order
  end

  def test_hook_execution_order
    order = []

    @hooks.register(:before_request) { order << :before }
    @hooks.register(:around_request) do |ctx, &block|
      order << :around_before
      result = block.call
      order << :around_after
      result
    end
    @hooks.register(:on_response) { order << :on_response }
    @hooks.register(:after_request) { order << :after }

    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert_equal [:before, :around_before, :on_response, :around_after, :after], order
  end

  def test_method_missing_delegates_to_http
    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    result = client.custom_method(:arg1, :arg2)

    assert_equal :result, result
    assert_equal [[:custom_method, :arg1, :arg2]], @mock_http.calls
  end

  def test_respond_to_missing
    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    assert client.respond_to?(:custom_method)
  end

  def test_context_includes_zenrows_headers
    received_headers = nil
    @hooks.register(:on_response) { |resp, ctx| received_headers = ctx[:zenrows_headers] }

    response = MockResponse.new(200, {
      "Concurrency-Limit" => "25",
      "X-Request-Cost" => "5.0"
    })
    @mock_http.stub_response(:get, "https://example.com", response)

    client = Zenrows::InstrumentedClient.new(@mock_http, hooks: @hooks, context_base: @context_base)
    client.get("https://example.com")

    assert_equal 25, received_headers[:concurrency_limit]
    assert_equal 5.0, received_headers[:request_cost]
  end
end
