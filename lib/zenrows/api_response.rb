# frozen_string_literal: true

require "json"

module Zenrows
  # Response wrapper for ZenRows API responses
  #
  # Provides convenient accessors for different response types based on
  # the options used in the request.
  #
  # @example HTML response
  #   response = api.get(url)
  #   response.html  # => "<html>..."
  #
  # @example JSON response with XHR data
  #   response = api.get(url, json_response: true)
  #   response.data  # => { "html" => "...", "xhr" => [...] }
  #   response.html  # => "<html>..."
  #   response.xhr   # => [...]
  #
  # @example Autoparse response
  #   response = api.get(url, autoparse: true)
  #   response.parsed  # => { "title" => "...", "price" => "..." }
  #
  # @example CSS extraction
  #   response = api.get(url, css_extractor: { title: 'h1' })
  #   response.extracted  # => { "title" => "Page Title" }
  #
  # @example Markdown response
  #   response = api.get(url, response_type: 'markdown')
  #   response.markdown  # => "# Page Title\n\n..."
  #
  # @author Ernest Bursa
  # @since 0.2.0
  # @api public
  class ApiResponse
    # @return [HTTP::Response] Raw HTTP response
    attr_reader :raw

    # @return [Integer] HTTP status code
    attr_reader :status

    # @return [Hash] Request options used
    attr_reader :options

    # Initialize response wrapper
    #
    # @param http_response [HTTP::Response] Raw HTTP response
    # @param options [Hash] Request options
    def initialize(http_response, options = {})
      @raw = http_response
      @status = http_response.status.code
      @options = options
      @body = http_response.body.to_s
      @parsed_json = nil
    end

    # Response body as string
    #
    # @return [String] Raw response body
    attr_reader :body

    # Parsed data (for JSON responses)
    #
    # @return [Hash, Array, String] Parsed response data
    def data
      @parsed_json ||= parse_body
    end

    # HTML content
    #
    # Returns HTML from json_response data or raw body
    #
    # @return [String] HTML content
    def html
      if json_response?
        data.is_a?(Hash) ? data["html"] : data
      else
        @body
      end
    end

    # Markdown content (when response_type: 'markdown')
    #
    # @return [String] Markdown content
    def markdown
      @body
    end

    # Parsed/extracted data (for autoparse or css_extractor)
    #
    # @return [Hash] Structured data
    def parsed
      data
    end

    # Alias for parsed data when using css_extractor
    #
    # @return [Hash] Extracted data
    def extracted
      data
    end

    # XHR/fetch request data (when json_response: true)
    #
    # @return [Array, nil] XHR request data
    def xhr
      data.is_a?(Hash) ? data["xhr"] : nil
    end

    # JS instructions execution report (when json_response: true)
    #
    # @return [Hash, nil] Instructions report
    def js_instructions_report
      data.is_a?(Hash) ? data["js_instructions_report"] : nil
    end

    # Screenshot data (when screenshot options used with json_response)
    #
    # @return [String, nil] Base64 encoded screenshot
    def screenshot
      data.is_a?(Hash) ? data["screenshot"] : nil
    end

    # Response headers
    #
    # @return [Hash] Response headers
    def headers
      @raw.headers.to_h
    end

    # Concurrency limit from headers
    #
    # @return [Integer, nil] Max concurrent requests
    def concurrency_limit
      headers["Concurrency-Limit"]&.to_i
    end

    # Remaining concurrency from headers
    #
    # @return [Integer, nil] Available concurrent request slots
    def concurrency_remaining
      headers["Concurrency-Remaining"]&.to_i
    end

    # Request cost from headers
    #
    # @return [Float, nil] Credit cost of request
    def request_cost
      headers["X-Request-Cost"]&.to_f
    end

    # Final URL after redirects
    #
    # @return [String, nil] Final URL
    def final_url
      headers["Zr-Final-Url"]
    end

    # Check if response is successful
    #
    # @return [Boolean]
    def success?
      status >= 200 && status < 300
    end

    private

    def json_response?
      options[:json_response] || options[:autoparse] || options[:css_extractor] || options[:outputs]
    end

    def parse_body
      return @body unless json_response? || looks_like_json?

      JSON.parse(@body)
    rescue JSON::ParserError
      @body
    end

    def looks_like_json?
      @body.start_with?("{") || @body.start_with?("[")
    end
  end
end
