# frozen_string_literal: true

require "http"
require "json"
require "cgi"

module Zenrows
  # REST API client for ZenRows Universal Scraper API
  #
  # Unlike the proxy-based Client, ApiClient calls the ZenRows API directly.
  # This enables features not available in proxy mode: autoparse, css_extractor,
  # response_type (markdown), and outputs.
  #
  # @example Basic usage
  #   api = Zenrows::ApiClient.new
  #   response = api.get('https://example.com')
  #
  # @example With autoparse
  #   response = api.get('https://amazon.com/dp/B01LD5GO7I', autoparse: true)
  #   puts response.data  # Structured product data
  #
  # @example With CSS extraction
  #   response = api.get(url, css_extractor: { title: 'h1', links: 'a @href' })
  #
  # @example With markdown output
  #   response = api.get(url, response_type: 'markdown')
  #
  # @author Ernest Bursa
  # @since 0.2.0
  # @api public
  class ApiClient
    # @return [String] ZenRows API key
    attr_reader :api_key

    # @return [String] API endpoint URL
    attr_reader :api_endpoint

    # @return [Configuration] Configuration instance
    attr_reader :config

    # Initialize API client
    #
    # @param api_key [String, nil] Override API key (uses global config if nil)
    # @param api_endpoint [String, nil] Override API endpoint (uses global config if nil)
    def initialize(api_key: nil, api_endpoint: nil)
      @config = Zenrows.configuration
      @api_key = api_key || @config.api_key
      @api_endpoint = api_endpoint || @config.api_endpoint
      @config.validate! unless api_key
    end

    # Make GET request through ZenRows API
    #
    # @param url [String] Target URL to scrape
    # @param options [Hash] Request options
    # @option options [Boolean] :autoparse Auto-extract structured data
    # @option options [Hash, CssExtractor] :css_extractor CSS selectors for extraction
    # @option options [String] :response_type Response format ('markdown')
    # @option options [String] :outputs Extract specific data ('headings,links,menus')
    # @option options [Boolean] :js_render Enable JavaScript rendering
    # @option options [Boolean] :premium_proxy Use residential proxies
    # @option options [String] :proxy_country Country code
    # @option options [Integer, Boolean] :wait Wait time in ms
    # @option options [String] :wait_for CSS selector to wait for
    # @option options [Boolean, String] :session_id Session persistence
    # @option options [Array, String] :js_instructions Browser automation
    # @option options [Boolean] :json_response Return JSON with XHR data
    # @option options [Boolean] :screenshot Take screenshot
    # @option options [Boolean] :screenshot_fullpage Full page screenshot
    # @option options [String] :screenshot_selector Screenshot element
    # @option options [String] :block_resources Block resources
    # @option options [String] :device Device emulation
    # @option options [Boolean] :antibot Enhanced antibot
    # @return [ApiResponse] Response wrapper
    # @raise [ConfigurationError] if API key not configured
    # @raise [AuthenticationError] if API key invalid
    # @raise [RateLimitError] if rate limited
    def get(url, **options)
      params = build_params(url, options)
      http_response = build_http_client.get(api_endpoint, params: params)
      handle_response(http_response, options)
    end

    # Make POST request through ZenRows API
    #
    # @param url [String] Target URL
    # @param body [String, Hash] Request body
    # @param options [Hash] Request options (same as #get)
    # @return [ApiResponse] Response wrapper
    def post(url, body: nil, **options)
      params = build_params(url, options)
      http_response = build_http_client.post(api_endpoint, params: params, body: body)
      handle_response(http_response, options)
    end

    private

    def build_http_client
      HTTP
        .timeout(connect: config.connect_timeout, read: config.read_timeout)
    end

    def build_params(url, options)
      params = {apikey: api_key, url: url}

      # API-mode only features
      params[:autoparse] = "true" if options[:autoparse]
      params[:response_type] = options[:response_type] if options[:response_type]
      params[:outputs] = options[:outputs] if options[:outputs]

      if options[:css_extractor]
        extractor = options[:css_extractor]
        params[:css_extractor] = extractor.to_json
      end

      # Common options (also available in proxy mode)
      params[:js_render] = "true" if options[:js_render]
      params[:premium_proxy] = "true" if options[:premium_proxy]
      params[:proxy_country] = options[:proxy_country] if options[:proxy_country]
      params[:json_response] = "true" if options[:json_response]
      params[:original_status] = "true" if options[:original_status]

      # Wait options
      if options[:wait]
        params[:wait] = (options[:wait] == true) ? 15000 : options[:wait]
      end
      params[:wait_for] = options[:wait_for] if options[:wait_for]

      # Session
      if options[:session_id]
        params[:session_id] = (options[:session_id] == true) ? rand(1..99999) : options[:session_id]
      end

      # Window dimensions
      params[:window_height] = options[:window_height] if options[:window_height]
      params[:window_width] = options[:window_width] if options[:window_width]

      # Screenshots
      params[:screenshot] = "true" if options[:screenshot]
      params[:screenshot_fullpage] = "true" if options[:screenshot_fullpage]
      params[:screenshot_selector] = options[:screenshot_selector] if options[:screenshot_selector]

      # JS instructions
      if options[:js_instructions]
        instructions = options[:js_instructions]
        instructions = instructions.to_json if instructions.respond_to?(:to_a)
        params[:js_instructions] = instructions
      end

      # Other options
      params[:block_resources] = options[:block_resources] if options[:block_resources]
      params[:device] = options[:device] if options[:device]
      params[:antibot] = "true" if options[:antibot]

      # Custom headers
      options[:headers]&.each do |key, value|
        params["custom_headers[#{key}]"] = value
      end

      params
    end

    def handle_response(http_response, options)
      case http_response.status.code
      when 200..299
        ApiResponse.new(http_response, options)
      when 401
        raise AuthenticationError, "Invalid API key"
      when 429
        retry_after = http_response.headers["Retry-After"]&.to_i
        raise RateLimitError.new("Rate limited", retry_after: retry_after)
      when 403
        raise BotDetectedError.new("Bot detected", suggestion: "Try premium_proxy or antibot options")
      else
        body = http_response.body.to_s
        raise Error, "API error (#{http_response.status}): #{body[0, 200]}"
      end
    end
  end
end
