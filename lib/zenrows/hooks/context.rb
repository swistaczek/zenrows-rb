# frozen_string_literal: true

module Zenrows
  class Hooks
    # Builds context hashes for hook callbacks
    #
    # Provides methods to create and enrich context objects passed to hooks.
    # Handles parsing of ZenRows-specific response headers.
    #
    # @author Ernest Bursa
    # @since 0.3.0
    # @api private
    class Context
      # ZenRows response headers to parse
      ZENROWS_HEADERS = {
        "Concurrency-Limit" => :concurrency_limit,
        "Concurrency-Remaining" => :concurrency_remaining,
        "X-Request-Cost" => :request_cost,
        "X-Request-Id" => :request_id,
        "Zr-Final-Url" => :final_url
      }.freeze

      class << self
        # Build context for a request
        #
        # @param method [Symbol] HTTP method (:get, :post, etc.)
        # @param url [String] Target URL
        # @param options [Hash] ZenRows options used for the request
        # @param backend [Symbol] Backend name (:http_rb, :net_http)
        # @return [Hash] Request context
        def for_request(method:, url:, options:, backend:)
          uri = parse_uri(url)

          {
            method: method,
            url: url,
            host: uri&.host,
            options: options.dup.freeze,
            started_at: Process.clock_gettime(Process::CLOCK_MONOTONIC),
            backend: backend,
            zenrows_headers: {}
          }
        end

        # Enrich context with response data
        #
        # Adds timing information and parses ZenRows headers from response.
        #
        # @param context [Hash] Existing request context
        # @param response [Object] HTTP response object
        # @return [Hash] Enriched context
        def enrich_with_response(context, response)
          headers = extract_headers(response)
          context[:zenrows_headers] = parse_zenrows_headers(headers)
          context[:completed_at] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          context[:duration] = context[:completed_at] - context[:started_at]
          context
        end

        private

        # Safely parse URI
        #
        # @param url [String] URL to parse
        # @return [URI, nil] Parsed URI or nil if invalid
        def parse_uri(url)
          URI.parse(url.to_s)
        rescue URI::InvalidURIError
          nil
        end

        # Extract headers from response object
        #
        # Handles different response object types (http.rb, Net::HTTP, etc.)
        #
        # @param response [Object] HTTP response object
        # @return [Hash] Headers as hash
        def extract_headers(response)
          case response
          when ->(r) { r.respond_to?(:headers) }
            headers_to_hash(response.headers)
          when ->(r) { r.respond_to?(:to_hash) }
            response.to_hash
          when ->(r) { r.respond_to?(:each_header) }
            # Net::HTTPResponse
            {}.tap { |h| response.each_header { |k, v| h[k] = v } }
          else
            {}
          end
        end

        # Convert headers object to hash
        #
        # @param headers [Object] Headers object
        # @return [Hash] Headers as hash
        def headers_to_hash(headers)
          if headers.respond_to?(:to_h)
            headers.to_h
          elsif headers.respond_to?(:to_hash)
            headers.to_hash
          else
            {}
          end
        end

        # Parse ZenRows-specific headers
        #
        # @param headers [Hash] Response headers
        # @return [Hash] Parsed ZenRows headers with typed values
        def parse_zenrows_headers(headers)
          result = {}

          ZENROWS_HEADERS.each do |header, key|
            # Try both exact case and lowercase
            value = headers[header] || headers[header.downcase]
            next unless value

            result[key] = cast_header_value(key, value)
          end

          result
        end

        # Cast header value to appropriate type
        #
        # @param key [Symbol] Header key
        # @param value [String] Raw header value
        # @return [Object] Typed value
        def cast_header_value(key, value)
          case key
          when :request_cost
            value.to_f
          when :concurrency_limit, :concurrency_remaining
            value.to_i
          else
            value.to_s
          end
        end
      end
    end
  end
end
