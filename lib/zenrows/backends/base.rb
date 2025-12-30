# frozen_string_literal: true

module Zenrows
  module Backends
    # Abstract base class for HTTP backends
    #
    # Backends are responsible for building configured HTTP clients
    # that route through the ZenRows proxy.
    #
    # @abstract Subclass and override {#build_client} to implement
    # @author Ernest Bursa
    # @since 0.1.0
    # @api public
    class Base
      # @return [Zenrows::Proxy] Proxy configuration builder
      attr_reader :proxy

      # @return [Zenrows::Configuration] Configuration instance
      attr_reader :config

      # @return [Zenrows::Hooks] Hook registry for this backend
      attr_reader :hooks

      # @param proxy [Zenrows::Proxy] Proxy configuration builder
      # @param config [Zenrows::Configuration] Configuration instance
      # @param hooks [Zenrows::Hooks, nil] Optional hook registry (defaults to config.hooks)
      def initialize(proxy:, config:, hooks: nil)
        @proxy = proxy
        @config = config
        @hooks = hooks || config.hooks&.dup || Hooks.new
      end

      # Build a configured HTTP client
      #
      # @param options [Hash] Request options
      # @return [Object] Configured HTTP client
      # @raise [NotImplementedError] if not implemented by subclass
      def build_client(options = {})
        raise NotImplementedError, "#{self.class}#build_client must be implemented"
      end

      # Build SSL context for proxy connections
      #
      # @return [OpenSSL::SSL::SSLContext] SSL context with verification disabled
      def ssl_context
        require "openssl"
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
        ctx
      end

      # Calculate appropriate timeout based on options
      #
      # @param options [Hash] Request options
      # @return [Hash] Timeout configuration with :connect and :read
      def calculate_timeouts(options = {})
        connect = config.connect_timeout
        read = config.read_timeout

        # Add time for JS rendering
        read += 15 if options[:js_render]

        # Add buffer for wait time
        if options[:wait]
          wait_seconds = normalize_wait_seconds(options[:wait])
          read += wait_seconds + 20
        end

        # Add time for screenshots
        read += 10 if options[:screenshot] || options[:screenshot_fullpage]

        # Add time for JS instructions
        if options[:js_instructions]
          instructions = options[:js_instructions]
          count = instructions.is_a?(Array) ? instructions.size : 1
          read += count * 5
        end

        {connect: connect, read: read}
      end

      # Wrap HTTP client with instrumentation if hooks are registered
      #
      # @param client [Object] The underlying HTTP client
      # @param options [Hash] Request options used for this client
      # @return [Object] Instrumented client or original if no hooks
      def wrap_client(client, options)
        return client if hooks.empty?

        InstrumentedClient.new(
          client,
          hooks: hooks,
          context_base: {
            options: options,
            backend: backend_name
          }
        )
      end

      # Get the backend name for context
      #
      # @return [Symbol] Backend identifier
      def backend_name
        :base
      end

      private

      # Normalize wait value to seconds
      #
      # @param wait [Boolean, Integer, Object] Wait value
      # @return [Integer] Wait time in seconds
      def normalize_wait_seconds(wait)
        case wait
        when true then 15
        when Integer then wait / 1000
        when ->(w) { w.respond_to?(:to_i) && w.respond_to?(:parts) }
          wait.to_i
        else
          (wait.to_i / 1000.0).ceil
        end
      end
    end
  end
end
