# frozen_string_literal: true

require "cgi"
require "json"
require "securerandom"

module Zenrows
  # Builds ZenRows proxy configuration
  #
  # ZenRows proxy encodes options in the password field of the proxy URL.
  # Format: http://API_KEY-opt1=val1&opt2=val2:@host:port
  #
  # @example Basic proxy configuration
  #   proxy = Zenrows::Proxy.new(api_key: 'key', host: 'proxy.zenrows.com', port: 1337)
  #   proxy.build(js_render: true, premium_proxy: true)
  #   # => { host: 'proxy.zenrows.com', port: 1337, username: 'key', password: 'js_render=true&premium_proxy=true' }
  #
  # @author Ernest Bursa
  # @since 0.1.0
  # @api public
  class Proxy
    # Maximum wait time in milliseconds (3 minutes)
    MAX_WAIT_MS = 180_000

    # Valid sticky TTL values for HTTP proxy
    VALID_STICKY_TTL = %w[30s 5m 30m 1h 1d].freeze

    # Valid region codes for HTTP proxy
    VALID_REGIONS = {
      "africa" => "af",
      "af" => "af",
      "asia pacific" => "ap",
      "ap" => "ap",
      "europe" => "eu",
      "eu" => "eu",
      "middle east" => "me",
      "me" => "me",
      "north america" => "na",
      "na" => "na",
      "south america" => "sa",
      "sa" => "sa",
      "global" => nil
    }.freeze

    # @return [String] ZenRows API key
    attr_reader :api_key

    # @return [String] Proxy host
    attr_reader :host

    # @return [Integer] Proxy port
    attr_reader :port

    # @param api_key [String] ZenRows API key
    # @param host [String] Proxy host
    # @param port [Integer] Proxy port
    def initialize(api_key:, host:, port:)
      @api_key = api_key
      @host = host
      @port = port
    end

    # Build proxy configuration hash for HTTP client
    #
    # @param options [Hash] Proxy options
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
    # @option options [Boolean] :original_status Return original HTTP status
    # @option options [Boolean] :screenshot Take screenshot
    # @option options [Boolean] :screenshot_fullpage Full page screenshot
    # @option options [String] :screenshot_selector Screenshot specific element
    # @option options [Boolean] :custom_headers Enable custom headers passthrough
    # @option options [String] :block_resources Block resources (image,media,font)
    # @option options [String] :device Device emulation ('mobile' or 'desktop')
    # @option options [Boolean] :antibot Enhanced antibot bypass mode
    # @option options [String] :session_ttl Session duration ('30s', '5m', '30m', '1h', '1d')
    # @return [Hash] Proxy configuration with :host, :port, :username, :password
    # @raise [WaitTimeError] if wait time exceeds 3 minutes
    # @raise [ArgumentError] if session_ttl is invalid
    def build(options = {})
      opts = options.dup
      proxy_params = build_params(opts)

      {
        host: host,
        port: port,
        username: api_key,
        password: proxy_params.map { |k, v| "#{k}=#{v}" }.join("&")
      }
    end

    # Build proxy URL string
    #
    # @param options [Hash] Proxy options (same as #build)
    # @return [String] Proxy URL
    def build_url(options = {})
      config = build(options)
      password = config[:password].empty? ? "" : config[:password]
      "http://#{config[:username]}:#{password}@#{config[:host]}:#{config[:port]}"
    end

    # Build proxy configuration as array [host, port, username, password]
    #
    # @param options [Hash] Proxy options (same as #build)
    # @return [Array<String, Integer, String, String>] Proxy array
    def build_array(options = {})
      config = build(options)
      [config[:host], config[:port], config[:username], config[:password]]
    end

    private

    # Build proxy parameters hash from options
    #
    # @param opts [Hash] Options hash (will be modified)
    # @return [Hash] Parameters for proxy password
    def build_params(opts)
      params = {}

      # Custom headers must be enabled first if we'll use headers
      params[:custom_headers] = true if opts[:custom_headers]

      # JavaScript rendering
      params[:js_render] = true if opts[:js_render]

      # Premium proxy
      params[:premium_proxy] = true if opts[:premium_proxy]

      # Wait time handling
      if opts[:wait]
        wait_ms = normalize_wait(opts[:wait])
        raise WaitTimeError, "Wait time cannot exceed 3 minutes (#{MAX_WAIT_MS}ms), got #{wait_ms}ms" if wait_ms > MAX_WAIT_MS

        params[:wait] = wait_ms
      end

      # Wait for selector
      params[:wait_for] = opts[:wait_for] if opts[:wait_for]

      # JSON response
      params[:json_response] = true if opts[:json_response]

      # Original status
      params[:original_status] = true if opts[:original_status]

      # Session ID
      if opts[:session_id] == true
        params[:session_id] = SecureRandom.random_number(1_000)
      elsif opts[:session_id]
        params[:session_id] = opts[:session_id]
      end

      # Window dimensions
      params[:window_height] = opts[:window_height].to_i if opts[:window_height]
      params[:window_width] = opts[:window_width].to_i if opts[:window_width]

      # Proxy country (auto-enables premium_proxy)
      if opts[:proxy_country]
        params[:proxy_country] = opts[:proxy_country].to_s.downcase
        params[:premium_proxy] = true
      end

      # JavaScript instructions
      if opts[:js_instructions]
        instructions = opts[:js_instructions]
        instructions = instructions.to_json if instructions.is_a?(Array)
        params[:js_instructions] = CGI.escape(instructions)
      end

      # Screenshots
      params[:screenshot] = true if opts[:screenshot]
      if opts[:screenshot_fullpage]
        params[:screenshot] = true
        params[:screenshot_fullpage] = true
      end
      if opts[:screenshot_selector]
        params[:screenshot] = true
        params[:screenshot_selector] = opts[:screenshot_selector]
      end

      # Block resources
      params[:block_resources] = opts[:block_resources] if opts[:block_resources]

      # Device emulation
      params[:device] = opts[:device].to_s if opts[:device]

      # Antibot bypass
      params[:antibot] = true if opts[:antibot]

      # Session TTL (duration)
      if opts[:session_ttl]
        ttl = opts[:session_ttl].to_s
        unless VALID_STICKY_TTL.include?(ttl)
          raise ArgumentError, "Invalid session_ttl: #{ttl}. Valid values: #{VALID_STICKY_TTL.join(", ")}"
        end
        params[:session_ttl] = ttl
      end

      # Auto-enable js_render if needed
      params[:js_render] = true if requires_js_render?(params)

      params
    end

    # Normalize wait time to milliseconds
    #
    # @param wait [Boolean, Integer, Object] Wait value
    # @return [Integer] Wait time in milliseconds
    def normalize_wait(wait)
      case wait
      when true then 15_000
      when Integer then wait
      when ->(w) { w.respond_to?(:to_i) && w.respond_to?(:parts) }
        # ActiveSupport::Duration - convert seconds to ms
        wait.to_i * 1000
      else
        wait.to_i
      end
    end

    # Check if JS rendering is required based on params
    #
    # @param params [Hash] Current parameters
    # @return [Boolean] true if js_render should be enabled
    def requires_js_render?(params)
      params[:wait] ||
        params[:wait_for] ||
        params[:json_response] ||
        params[:window_height] ||
        params[:window_width] ||
        params[:js_instructions] ||
        params[:screenshot] ||
        params[:screenshot_fullpage] ||
        params[:screenshot_selector]
    end
  end
end
