# frozen_string_literal: true

require "test_helper"

class HooksContextTest < Minitest::Test
  def test_for_request_builds_context
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "https://example.com/path",
      options: {js_render: true},
      backend: :http_rb
    )

    assert_equal :get, context[:method]
    assert_equal "https://example.com/path", context[:url]
    assert_equal "example.com", context[:host]
    assert_equal({js_render: true}, context[:options])
    assert_equal :http_rb, context[:backend]
    assert_instance_of Float, context[:started_at]
    assert_equal({}, context[:zenrows_headers])
  end

  def test_for_request_with_invalid_url
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "not a valid url::::",
      options: {},
      backend: :http_rb
    )

    assert_nil context[:host]
  end

  def test_for_request_freezes_options
    options = {js_render: true}
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "https://example.com",
      options: options,
      backend: :http_rb
    )

    assert context[:options].frozen?
    # Original should not be frozen
    refute options.frozen?
  end

  def test_enrich_with_response_parses_zenrows_headers
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "https://example.com",
      options: {},
      backend: :http_rb
    )

    response = MockResponse.new(200, {
      "Concurrency-Limit" => "25",
      "Concurrency-Remaining" => "23",
      "X-Request-Cost" => "5.5",
      "X-Request-Id" => "abc123",
      "Zr-Final-Url" => "https://example.com/final"
    })

    Zenrows::Hooks::Context.enrich_with_response(context, response)

    assert_equal 25, context[:zenrows_headers][:concurrency_limit]
    assert_equal 23, context[:zenrows_headers][:concurrency_remaining]
    assert_equal 5.5, context[:zenrows_headers][:request_cost]
    assert_equal "abc123", context[:zenrows_headers][:request_id]
    assert_equal "https://example.com/final", context[:zenrows_headers][:final_url]
    assert_instance_of Float, context[:completed_at]
    assert_instance_of Float, context[:duration]
  end

  def test_enrich_with_response_handles_missing_headers
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "https://example.com",
      options: {},
      backend: :http_rb
    )

    response = MockResponse.new(200, {})

    Zenrows::Hooks::Context.enrich_with_response(context, response)

    assert_equal({}, context[:zenrows_headers])
  end

  def test_enrich_with_response_handles_lowercase_headers
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "https://example.com",
      options: {},
      backend: :http_rb
    )

    response = MockResponse.new(200, {
      "concurrency-limit" => "10",
      "x-request-cost" => "2.0"
    })

    Zenrows::Hooks::Context.enrich_with_response(context, response)

    assert_equal 10, context[:zenrows_headers][:concurrency_limit]
    assert_equal 2.0, context[:zenrows_headers][:request_cost]
  end

  def test_enrich_calculates_duration
    context = Zenrows::Hooks::Context.for_request(
      method: :get,
      url: "https://example.com",
      options: {},
      backend: :http_rb
    )

    sleep 0.01 # Small delay

    response = MockResponse.new(200, {})

    Zenrows::Hooks::Context.enrich_with_response(context, response)

    assert context[:duration] >= 0.01
    assert context[:completed_at] > context[:started_at]
  end
end
