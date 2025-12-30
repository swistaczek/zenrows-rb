# frozen_string_literal: true

require "monitor"

module Zenrows
  # Global configuration for Zenrows client
  #
  # @example Configure with block
  #   Zenrows.configure do |config|
  #     config.api_key = 'YOUR_API_KEY'
  #     config.host = 'superproxy.zenrows.com'
  #     config.port = 1337
  #   end
  #
  # @example Configure directly
  #   Zenrows.configuration.api_key = 'YOUR_API_KEY'
  #
  # @author Ernest Bursa
  # @since 0.1.0
  # @api public
  class Configuration
    include MonitorMixin

    # @return [String, nil] ZenRows API key (required)
    attr_accessor :api_key

    # @return [String] ZenRows proxy host
    attr_accessor :host

    # @return [Integer] ZenRows proxy port
    attr_accessor :port

    # @return [Integer] Default connection timeout in seconds
    attr_accessor :connect_timeout

    # @return [Integer] Default read timeout in seconds
    attr_accessor :read_timeout

    # @return [Symbol] HTTP backend to use (:http_rb, :faraday, :net_http)
    attr_accessor :backend

    # @return [Logger, nil] Logger instance for debug output
    attr_accessor :logger

    # @return [String] ZenRows API endpoint for ApiClient
    attr_accessor :api_endpoint

    # @return [Zenrows::Hooks] Hook registry for request lifecycle events
    attr_reader :hooks

    # Default configuration values
    DEFAULTS = {
      host: "superproxy.zenrows.com",
      port: 1337,
      api_endpoint: "https://api.zenrows.com/v1/",
      connect_timeout: 5,
      read_timeout: 180,
      backend: :http_rb
    }.freeze

    def initialize
      super # Initialize MonitorMixin
      reset!
    end

    # Reset configuration to defaults
    #
    # @return [void]
    def reset!
      synchronize do
        @api_key = nil
        @host = DEFAULTS[:host]
        @port = DEFAULTS[:port]
        @api_endpoint = DEFAULTS[:api_endpoint]
        @connect_timeout = DEFAULTS[:connect_timeout]
        @read_timeout = DEFAULTS[:read_timeout]
        @backend = DEFAULTS[:backend]
        @logger = nil
        @hooks = Hooks.new
      end
    end

    # Register a callback to run before each request
    #
    # @param callable [#call, nil] Callable object
    # @yield [context] Block to execute
    # @yieldparam context [Hash] Request context
    # @return [self]
    #
    # @example
    #   config.before_request { |ctx| puts "Starting: #{ctx[:url]}" }
    def before_request(callable = nil, &block)
      hooks.register(:before_request, callable, &block)
      self
    end

    # Register a callback to run after each request (always runs)
    #
    # @param callable [#call, nil] Callable object
    # @yield [context] Block to execute
    # @yieldparam context [Hash] Request context
    # @return [self]
    #
    # @example
    #   config.after_request { |ctx| puts "Finished: #{ctx[:duration]}s" }
    def after_request(callable = nil, &block)
      hooks.register(:after_request, callable, &block)
      self
    end

    # Register a callback to run on successful response
    #
    # @param callable [#call, nil] Callable object
    # @yield [response, context] Block to execute
    # @yieldparam response [Object] HTTP response
    # @yieldparam context [Hash] Request context with ZenRows headers
    # @return [self]
    #
    # @example Log by host
    #   config.on_response { |resp, ctx| puts "#{ctx[:host]} -> #{resp.status}" }
    #
    # @example Track costs
    #   config.on_response do |resp, ctx|
    #     cost = ctx[:zenrows_headers][:request_cost]
    #     StatsD.increment('zenrows.cost', cost) if cost
    #   end
    def on_response(callable = nil, &block)
      hooks.register(:on_response, callable, &block)
      self
    end

    # Register a callback to run on request error
    #
    # @param callable [#call, nil] Callable object
    # @yield [error, context] Block to execute
    # @yieldparam error [Exception] The error that occurred
    # @yieldparam context [Hash] Request context
    # @return [self]
    #
    # @example
    #   config.on_error { |err, ctx| Sentry.capture_exception(err) }
    def on_error(callable = nil, &block)
      hooks.register(:on_error, callable, &block)
      self
    end

    # Register a callback to wrap around requests
    #
    # Around callbacks can modify timing, add retries, etc.
    # The block MUST call the passed block and return its result.
    #
    # @param callable [#call, nil] Callable object
    # @yield [context, &block] Block to execute
    # @yieldparam context [Hash] Request context
    # @yieldparam block [Proc] Block to call to execute the request
    # @return [self]
    #
    # @example Timing
    #   config.around_request do |ctx, &block|
    #     start = Time.now
    #     response = block.call
    #     puts "Request took #{Time.now - start}s"
    #     response
    #   end
    def around_request(callable = nil, &block)
      hooks.register(:around_request, callable, &block)
      self
    end

    # Add a subscriber object for hook events
    #
    # Subscribers can implement any of: before_request, after_request,
    # on_response, on_error, around_request.
    #
    # @param subscriber [Object] Object responding to hook methods
    # @return [self]
    #
    # @example
    #   class MySubscriber
    #     def on_response(response, context)
    #       puts response.status
    #     end
    #   end
    #   config.add_subscriber(MySubscriber.new)
    def add_subscriber(subscriber)
      hooks.add_subscriber(subscriber)
      self
    end

    # Validate that required configuration is present
    #
    # @raise [ConfigurationError] if api_key is missing
    # @return [true] if configuration is valid
    def validate!
      raise ConfigurationError, "api_key is required" if api_key.nil? || api_key.empty?

      true
    end

    # Check if configuration is valid
    #
    # @return [Boolean] true if configuration is valid
    def valid?
      validate!
      true
    rescue ConfigurationError
      false
    end

    # Convert configuration to hash
    #
    # @return [Hash] configuration as hash
    def to_h
      {
        api_key: api_key,
        host: host,
        port: port,
        api_endpoint: api_endpoint,
        connect_timeout: connect_timeout,
        read_timeout: read_timeout,
        backend: backend
      }
    end
  end

  class << self
    # @return [Configuration] Global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure Zenrows with a block
    #
    # @example
    #   Zenrows.configure do |config|
    #     config.api_key = 'YOUR_API_KEY'
    #   end
    #
    # @yield [Configuration] configuration instance
    # @return [Configuration] configuration instance
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Reset configuration to defaults
    #
    # @return [void]
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
