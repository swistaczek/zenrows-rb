# frozen_string_literal: true

require "test_helper"

class ApiResponseTest < Minitest::Test
  def test_html_response
    http_response = mock_response("<html><body>Test</body></html>", 200)
    response = Zenrows::ApiResponse.new(http_response)

    assert_equal "<html><body>Test</body></html>", response.html
    assert_equal "<html><body>Test</body></html>", response.body
    assert_equal 200, response.status
    assert_predicate response, :success?
  end

  def test_json_response_with_html
    body = '{"html":"<html>Test</html>","xhr":[]}'
    http_response = mock_response(body, 200)
    response = Zenrows::ApiResponse.new(http_response, json_response: true)

    assert_equal "<html>Test</html>", response.html
    assert_empty response.xhr
  end

  def test_markdown_response
    body = "# Title\n\nParagraph text"
    http_response = mock_response(body, 200)
    response = Zenrows::ApiResponse.new(http_response, response_type: "markdown")

    assert_equal "# Title\n\nParagraph text", response.markdown
  end

  def test_autoparse_response
    body = '{"title":"Product Name","price":"$29.99"}'
    http_response = mock_response(body, 200)
    response = Zenrows::ApiResponse.new(http_response, autoparse: true)

    assert_equal "Product Name", response.parsed["title"]
    assert_equal "$29.99", response.parsed["price"]
  end

  def test_css_extractor_response
    body = '{"title":"Page Title","links":["link1","link2"]}'
    http_response = mock_response(body, 200)
    response = Zenrows::ApiResponse.new(http_response, css_extractor: {title: "h1"})

    assert_equal "Page Title", response.extracted["title"]
    assert_equal ["link1", "link2"], response.extracted["links"]
  end

  def test_js_instructions_report
    body = '{"html":"...","js_instructions_report":{"instructions_executed":2}}'
    http_response = mock_response(body, 200)
    response = Zenrows::ApiResponse.new(http_response, json_response: true)

    assert_equal({"instructions_executed" => 2}, response.js_instructions_report)
  end

  def test_headers_accessors
    headers = {
      "Concurrency-Limit" => "200",
      "Concurrency-Remaining" => "199",
      "X-Request-Cost" => "0.001",
      "Zr-Final-Url" => "https://example.com/final"
    }
    http_response = mock_response("", 200, headers)
    response = Zenrows::ApiResponse.new(http_response)

    assert_equal 200, response.concurrency_limit
    assert_equal 199, response.concurrency_remaining
    assert_in_delta 0.001, response.request_cost
    assert_equal "https://example.com/final", response.final_url
  end

  def test_success_status_codes
    [200, 201, 204, 299].each do |code|
      http_response = mock_response("", code)
      response = Zenrows::ApiResponse.new(http_response)

      assert_predicate response, :success?, "Expected #{code} to be success"
    end
  end

  def test_non_success_status_codes
    [400, 401, 403, 404, 500].each do |code|
      http_response = mock_response("", code)
      response = Zenrows::ApiResponse.new(http_response)

      refute_predicate response, :success?, "Expected #{code} to not be success"
    end
  end

  private

  def mock_response(body, status, headers = {})
    MockHttpResponse.new(body, status, headers)
  end

  class MockHttpResponse
    attr_reader :body, :headers

    def initialize(body, status, headers = {})
      @body = MockBody.new(body)
      @status = MockStatus.new(status)
      @headers = MockHeaders.new(headers)
    end

    attr_reader :status

    class MockBody
      def initialize(content)
        @content = content
      end

      def to_s
        @content
      end
    end

    class MockStatus
      def initialize(code)
        @code = code
      end

      attr_reader :code
    end

    class MockHeaders
      def initialize(headers)
        @headers = headers
      end

      def [](key)
        @headers[key]
      end

      def to_h
        @headers
      end
    end
  end
end
