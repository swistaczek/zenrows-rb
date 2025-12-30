# frozen_string_literal: true

require "test_helper"
require "logger"
require "stringio"

class LogSubscriberTest < Minitest::Test
  def setup
    @output = StringIO.new
    @logger = Logger.new(@output)
    @logger.level = Logger::DEBUG
    @subscriber = Zenrows::Hooks::LogSubscriber.new(logger: @logger)
  end

  def test_before_request_logs_debug
    context = {method: :get, url: "https://example.com"}

    @subscriber.before_request(context)

    assert_includes @output.string, "ZenRows request: GET https://example.com"
  end

  def test_on_response_logs_info_with_status
    response = MockResponse.new(200)

    context = {
      url: "https://example.com",
      duration: 1.5,
      zenrows_headers: {request_cost: 5.0}
    }

    @subscriber.on_response(response, context)

    assert_includes @output.string, "ZenRows https://example.com -> 200"
    assert_includes @output.string, "1.5s"
    assert_includes @output.string, "cost: 5.0"
  end

  def test_on_response_formats_milliseconds
    response = MockResponse.new(200)

    context = {
      url: "https://example.com",
      duration: 0.150,
      zenrows_headers: {}
    }

    @subscriber.on_response(response, context)

    assert_includes @output.string, "150ms"
  end

  def test_on_error_logs_error
    error = StandardError.new("Connection failed")
    context = {
      url: "https://example.com",
      zenrows_headers: {request_id: "req123"}
    }

    @subscriber.on_error(error, context)

    assert_includes @output.string, "ZenRows https://example.com failed"
    assert_includes @output.string, "StandardError"
    assert_includes @output.string, "Connection failed"
    assert_includes @output.string, "request_id: req123"
  end

  def test_uses_global_logger_when_none_provided
    Zenrows.configure do |c|
      c.api_key = "test"
      c.logger = @logger
    end

    subscriber = Zenrows::Hooks::LogSubscriber.new
    subscriber.before_request({method: :get, url: "https://test.com"})

    assert_includes @output.string, "https://test.com"
  ensure
    Zenrows.reset_configuration!
  end

  def test_handles_nil_logger
    subscriber = Zenrows::Hooks::LogSubscriber.new(logger: nil)

    # Should not raise
    subscriber.before_request({method: :get, url: "https://example.com"})
    subscriber.on_response(MockResponse.new(200), {url: "x", zenrows_headers: {}})
    subscriber.on_error(StandardError.new, {url: "x", zenrows_headers: {}})
  end

  def test_handles_status_object_with_code
    # Create a response with a status object that has a code method
    status = Object.new
    status.define_singleton_method(:code) { 201 }

    response = Object.new
    response.define_singleton_method(:status) { status }

    context = {url: "https://example.com", zenrows_headers: {}}

    @subscriber.on_response(response, context)

    assert_includes @output.string, "201"
  end
end
