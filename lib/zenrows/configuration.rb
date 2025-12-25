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
      end
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
