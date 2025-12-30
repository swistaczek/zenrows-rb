# frozen_string_literal: true

module Zenrows
  # Main client for ZenRows proxy
  #
  # The client builds configured HTTP clients that route through
  # the ZenRows proxy with specified options.
  #
  # @example Basic usage
  #   Zenrows.configure do |c|
  #     c.api_key = 'YOUR_API_KEY'
  #   end
  #
  #   client = Zenrows::Client.new
  #   http = client.http(js_render: true)
  #   response = http.get('https://example.com')
  #
  # @example With custom configuration
  #   client = Zenrows::Client.new(api_key: 'KEY', host: 'proxy.zenrows.com')
  #   http = client.http(premium_proxy: true, proxy_country: 'us')
  #
  # @example With per-client hooks
  #   client = Zenrows::Client.new do |c|
  #     c.on_response { |resp, ctx| puts "#{ctx[:host]} -> #{resp.status}" }
  #   end
  #
  # @author Ernest Bursa
  # @since 0.1.0
  # @api public
  class Client
    # @return [Configuration] Client configuration
    attr_reader :config

    # @return [Proxy] Proxy builder instance
    attr_reader :proxy

    # @return [Backends::Base] HTTP backend instance
    attr_reader :backend

    # @return [Hooks] Hook registry for this client
    attr_reader :hooks

    # Initialize a new client
    #
    # @param api_key [String, nil] Override API key from global config
    # @param host [String, nil] Override proxy host
    # @param port [Integer, nil] Override proxy port
    # @param backend [Symbol] Backend to use (:http_rb)
    # @yield [config] Optional block for per-client configuration (hooks, etc.)
    # @yieldparam config [Configuration] Client configuration for hook registration
    # @raise [ConfigurationError] if api_key is not configured
    #
    # @example With per-client hooks
    #   client = Zenrows::Client.new do |c|
    #     c.on_response { |resp, ctx| puts resp.status }
    #   end
    def initialize(api_key: nil, host: nil, port: nil, backend: nil, &block)
      @config = build_config(api_key: api_key, host: host, port: port, backend: backend)
      @config.validate!

      # Build hooks: start with global, allow per-client additions
      @hooks = block ? build_hooks(&block) : Zenrows.configuration.hooks.dup

      @proxy = Proxy.new(
        api_key: @config.api_key,
        host: @config.host,
        port: @config.port
      )

      @backend = build_backend
    end

    # Build a configured HTTP client
    #
    # @param options [Hash] Request options
    # @option options [Boolean] :js_render Enable JavaScript rendering
    # @option options [Boolean] :premium_proxy Use residential proxies
    # @option options [String] :proxy_country Country code (us, gb, de, etc.)
    # @option options [Boolean, Integer] :wait Wait time (true=15s, Integer=ms)
    # @option options [String] :wait_for CSS selector to wait for
    # @option options [Boolean, String, Integer] :session_id Session persistence
    # @option options [Integer] :window_height Browser window height
    # @option options [Integer] :window_width Browser window width
    # @option options [Array, String] :js_instructions JavaScript instructions
    # @option options [Boolean] :json_response Return JSON instead of HTML
    # @option options [Boolean] :screenshot Take screenshot
    # @option options [Boolean] :screenshot_fullpage Full page screenshot
    # @option options [String] :screenshot_selector Screenshot specific element
    # @option options [Hash] :headers Custom HTTP headers
    # @option options [String] :block_resources Block resources (image,media,font)
    # @return [HTTP::Client] Configured HTTP client ready for requests
    #
    # @example Basic request
    #   http = client.http(js_render: true)
    #   response = http.get(url)
    #
    # @example With premium proxy and country
    #   http = client.http(premium_proxy: true, proxy_country: 'us')
    #   response = http.get(url)
    def http(options = {})
      backend.build_client(options)
    end

    # Get SSL context for proxy connections
    #
    # ZenRows proxy requires SSL verification to be disabled.
    # This is automatically applied when using #http, but exposed
    # for advanced use cases.
    #
    # @return [OpenSSL::SSL::SSLContext] SSL context
    def ssl_context
      backend.ssl_context
    end

    # Get proxy configuration for given options
    #
    # @param options [Hash] Proxy options
    # @return [Hash] Proxy configuration with :host, :port, :username, :password
    def proxy_config(options = {})
      proxy.build(options)
    end

    # Get proxy URL for given options
    #
    # @param options [Hash] Proxy options
    # @return [String] Proxy URL
    def proxy_url(options = {})
      proxy.build_url(options)
    end

    private

    # Build configuration from params and global config
    #
    # @param api_key [String, nil] Override API key
    # @param host [String, nil] Override host
    # @param port [Integer, nil] Override port
    # @param backend [Symbol, nil] Override backend
    # @return [Configuration] Configuration instance
    def build_config(api_key:, host:, port:, backend:)
      cfg = Configuration.new

      # Start with global config values
      global = Zenrows.configuration
      cfg.api_key = global.api_key
      cfg.host = global.host
      cfg.port = global.port
      cfg.connect_timeout = global.connect_timeout
      cfg.read_timeout = global.read_timeout
      cfg.backend = global.backend
      cfg.logger = global.logger

      # Override with provided values
      cfg.api_key = api_key if api_key
      cfg.host = host if host
      cfg.port = port if port
      cfg.backend = backend if backend

      cfg
    end

    # Build backend instance based on configuration
    #
    # @return [Backends::Base] Backend instance
    # @raise [ConfigurationError] if backend is not supported
    def build_backend
      backend_name = resolve_backend
      case backend_name
      when :http_rb
        Backends::HttpRb.new(proxy: proxy, config: config, hooks: hooks)
      when :net_http
        Backends::NetHttp.new(proxy: proxy, config: config, hooks: hooks)
      else
        raise ConfigurationError, "Unsupported backend: #{backend_name}. Use :http_rb or :net_http"
      end
    end

    # Build hooks registry for this client
    #
    # Starts with global hooks, then applies per-client hooks from block.
    #
    # @yield [config] Block for registering per-client hooks
    # @return [Hooks] Combined hooks registry
    def build_hooks
      # Start with a copy of global hooks
      client_hooks = Zenrows.configuration.hooks.dup

      # Create a temporary config-like object for hook registration
      hook_config = HookConfigurator.new(client_hooks)
      yield(hook_config)

      client_hooks
    end

    # Resolve which backend to use
    #
    # @return [Symbol] Backend name
    def resolve_backend
      return config.backend if config.backend == :net_http

      # Try http_rb first (preferred), fallback to net_http
      if config.backend == :http_rb
        return :http_rb if http_rb_available?
        return :net_http
      end

      config.backend
    end

    # Check if http.rb gem is available
    #
    # @return [Boolean]
    def http_rb_available?
      require "http"
      true
    rescue LoadError
      false
    end
  end

  # Helper class for per-client hook configuration
  #
  # Provides the same hook registration DSL as Configuration.
  #
  # @api private
  class HookConfigurator
    # @param hooks [Hooks] Hook registry to configure
    def initialize(hooks)
      @hooks = hooks
    end

    # Register a before_request callback
    def before_request(callable = nil, &block)
      @hooks.register(:before_request, callable, &block)
      self
    end

    # Register an after_request callback
    def after_request(callable = nil, &block)
      @hooks.register(:after_request, callable, &block)
      self
    end

    # Register an on_response callback
    def on_response(callable = nil, &block)
      @hooks.register(:on_response, callable, &block)
      self
    end

    # Register an on_error callback
    def on_error(callable = nil, &block)
      @hooks.register(:on_error, callable, &block)
      self
    end

    # Register an around_request callback
    def around_request(callable = nil, &block)
      @hooks.register(:around_request, callable, &block)
      self
    end

    # Add a subscriber object
    def add_subscriber(subscriber)
      @hooks.add_subscriber(subscriber)
      self
    end
  end
end
