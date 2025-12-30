# frozen_string_literal: true

module Zenrows
  # Wrapper around HTTP clients that executes hooks on requests
  #
  # Decorates an HTTP client (from http.rb or Net::HTTP) to add
  # hook execution before, during, and after requests.
  #
  # @example
  #   client = InstrumentedClient.new(http_client,
  #     hooks: hooks_registry,
  #     context_base: { backend: :http_rb, options: { js_render: true } }
  #   )
  #   response = client.get("https://example.com")
  #
  # @author Ernest Bursa
  # @since 0.3.0
  # @api private
  class InstrumentedClient
    # HTTP methods to instrument
    HTTP_METHODS = %i[get post put patch delete head options].freeze

    # @return [Object] Underlying HTTP client
    attr_reader :http

    # @return [Hooks] Hook registry
    attr_reader :hooks

    # @return [Hash] Base context for all requests
    attr_reader :context_base

    # Create a new instrumented client
    #
    # @param http [Object] Underlying HTTP client (HTTP::Client, NetHttpClient, etc.)
    # @param hooks [Hooks] Hook registry to use
    # @param context_base [Hash] Base context to merge into all requests
    def initialize(http, hooks:, context_base:)
      @http = http
      @hooks = hooks
      @context_base = context_base
    end

    # Instrumented GET request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def get(url, **options)
      instrument(:get, url, options) { @http.get(url, **options) }
    end

    # Instrumented POST request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def post(url, **options)
      instrument(:post, url, options) { @http.post(url, **options) }
    end

    # Instrumented PUT request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def put(url, **options)
      instrument(:put, url, options) { @http.put(url, **options) }
    end

    # Instrumented PATCH request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def patch(url, **options)
      instrument(:patch, url, options) { @http.patch(url, **options) }
    end

    # Instrumented DELETE request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def delete(url, **options)
      instrument(:delete, url, options) { @http.delete(url, **options) }
    end

    # Instrumented HEAD request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def head(url, **options)
      instrument(:head, url, options) { @http.head(url, **options) }
    end

    # Instrumented OPTIONS request
    #
    # @param url [String] URL to request
    # @param options [Hash] Request options
    # @return [Object] HTTP response
    def options(url, **options)
      instrument(:options, url, options) { @http.options(url, **options) }
    end

    # Delegate unknown methods to underlying client
    #
    # @param method [Symbol] Method name
    # @param args [Array] Method arguments
    # @param kwargs [Hash] Keyword arguments
    # @param block [Proc] Block to pass
    # @return [Object] Result of delegated method
    def method_missing(method, *args, **kwargs, &block)
      if @http.respond_to?(method)
        @http.public_send(method, *args, **kwargs, &block)
      else
        super
      end
    end

    # Check if method is supported
    #
    # @param method [Symbol] Method name
    # @param include_private [Boolean] Include private methods
    # @return [Boolean] true if method is supported
    def respond_to_missing?(method, include_private = false)
      @http.respond_to?(method, include_private) || super
    end

    private

    # Instrument an HTTP request with hooks
    #
    # @param method [Symbol] HTTP method
    # @param url [String] Request URL
    # @param options [Hash] Request options
    # @yield Block that executes the actual HTTP request
    # @return [Object] HTTP response
    def instrument(method, url, options, &block)
      context = build_context(method, url, options)

      # Run before hooks
      hooks.run(:before_request, context)

      # Run around hooks and execute request
      response = hooks.run_around(context) do
        execute_request(context, &block)
      end

      response
    ensure
      # Run after hooks (always, even on error)
      hooks.run(:after_request, context) if context
    end

    # Build context for a request
    #
    # @param method [Symbol] HTTP method
    # @param url [String] Request URL
    # @param options [Hash] Request options
    # @return [Hash] Request context
    def build_context(method, url, options)
      Hooks::Context.for_request(
        method: method,
        url: url,
        options: context_base[:options].merge(options),
        backend: context_base[:backend]
      )
    end

    # Execute the actual request with error handling
    #
    # @param context [Hash] Request context
    # @yield Block that executes the HTTP request
    # @return [Object] HTTP response
    def execute_request(context)
      response = yield
      Hooks::Context.enrich_with_response(context, response)
      hooks.run(:on_response, response, context)
      response
    rescue => e
      context[:error] = e
      hooks.run(:on_error, e, context)
      raise
    end
  end
end
