# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"

module Zenrows
  module Backends
    # Net::HTTP backend adapter (stdlib fallback)
    #
    # Uses Ruby's built-in Net::HTTP when http.rb is not available.
    # Provides basic proxy support with SSL verification disabled.
    #
    # @example Basic usage
    #   backend = Zenrows::Backends::NetHttp.new(proxy: proxy, config: config)
    #   http = backend.build_client(js_render: true)
    #   response = http.get(url)
    #
    # @author Ernest Bursa
    # @since 0.2.1
    # @api public
    class NetHttp < Base
      # Build a configured HTTP client wrapper
      #
      # @param options [Hash] Request options
      # @return [NetHttpClient, InstrumentedClient] Configured client wrapper (instrumented if hooks registered)
      def build_client(options = {})
        opts = options.dup
        headers = opts.delete(:headers) || {}
        opts[:custom_headers] = true if headers.any?

        proxy_config = proxy.build(opts)
        timeouts = calculate_timeouts(opts)

        client = NetHttpClient.new(
          proxy_config: proxy_config,
          headers: headers,
          timeouts: timeouts,
          ssl_context: ssl_context
        )

        # Wrap with instrumentation if hooks registered
        wrap_client(client, opts)
      end

      # @return [Symbol] Backend identifier
      def backend_name
        :net_http
      end
    end

    # Wrapper around Net::HTTP that mimics http.rb interface
    #
    # @api private
    class NetHttpClient
      # @param proxy_config [Hash] Proxy configuration
      # @param headers [Hash] Default headers
      # @param timeouts [Hash] Timeout configuration
      # @param ssl_context [OpenSSL::SSL::SSLContext] SSL context
      def initialize(proxy_config:, headers:, timeouts:, ssl_context:)
        @proxy_config = proxy_config
        @headers = headers
        @timeouts = timeouts
        @ssl_context = ssl_context
      end

      # Make GET request
      #
      # @param url [String] Target URL
      # @param options [Hash] Request options
      # @return [NetHttpResponse] Response wrapper
      def get(url, **options)
        uri = URI.parse(url)
        request(uri, Net::HTTP::Get.new(uri), options)
      end

      # Make POST request
      #
      # @param url [String] Target URL
      # @param body [String, nil] Request body
      # @param options [Hash] Request options
      # @return [NetHttpResponse] Response wrapper
      def post(url, body: nil, **options)
        uri = URI.parse(url)
        req = Net::HTTP::Post.new(uri)
        req.body = body if body
        request(uri, req, options)
      end

      private

      def request(uri, req, options)
        @headers.each { |k, v| req[k] = v }

        http = Net::HTTP.new(
          uri.host,
          uri.port,
          @proxy_config[:host],
          @proxy_config[:port],
          @proxy_config[:username],
          @proxy_config[:password]
        )

        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeouts[:connect]
        http.read_timeout = @timeouts[:read]

        # Apply SSL context
        ctx = options[:ssl_context] || @ssl_context
        http.verify_mode = ctx.verify_mode if ctx

        response = http.request(req)
        NetHttpResponse.new(response)
      end
    end

    # Response wrapper that mimics http.rb response interface
    #
    # @api private
    class NetHttpResponse
      # @return [Net::HTTPResponse] Raw response
      attr_reader :raw

      def initialize(response)
        @raw = response
      end

      # @return [String] Response body
      def body
        @raw.body
      end

      # @return [Integer] HTTP status code
      def status
        @raw.code.to_i
      end

      # @return [Hash] Response headers
      def headers
        @raw.to_hash.transform_values(&:first)
      end

      # Alias for body (http.rb compatibility)
      def to_s
        body
      end
    end
  end
end
