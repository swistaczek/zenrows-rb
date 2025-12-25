# frozen_string_literal: true

require "http"

module Zenrows
  module Backends
    # HTTP.rb backend adapter
    #
    # Uses the http.rb gem to build configured HTTP clients
    # that route through the ZenRows proxy.
    #
    # @example Basic usage
    #   backend = Zenrows::Backends::HttpRb.new(proxy: proxy, config: config)
    #   http = backend.build_client(js_render: true)
    #   response = http.get(url, ssl_context: backend.ssl_context)
    #
    # @author Ernest Bursa
    # @since 0.1.0
    # @api public
    class HttpRb < Base
      # Build a configured HTTP client
      #
      # @param options [Hash] Request options
      # @option options [Boolean] :js_render Enable JavaScript rendering
      # @option options [Boolean] :premium_proxy Use residential proxies
      # @option options [String] :proxy_country Country code
      # @option options [Boolean, Integer] :wait Wait time
      # @option options [String] :wait_for CSS selector to wait for
      # @option options [Hash] :headers Custom HTTP headers
      # @return [HTTP::Client] Configured HTTP client
      def build_client(options = {})
        opts = options.dup
        headers = opts.delete(:headers) || {}

        # Enable custom_headers if we have headers
        opts[:custom_headers] = true if headers.any?

        # Get proxy configuration
        proxy_config = proxy.build(opts)

        # Calculate timeouts
        timeouts = calculate_timeouts(opts)

        # Build HTTP client
        client = HTTP
          .timeout(connect: timeouts[:connect], read: timeouts[:read])
          .headers(headers)

        # Configure proxy
        client.via(
          proxy_config[:host],
          proxy_config[:port],
          proxy_config[:username],
          proxy_config[:password]
        )
      end
    end
  end
end
