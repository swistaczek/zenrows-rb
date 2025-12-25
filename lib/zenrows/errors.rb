# frozen_string_literal: true

module Zenrows
  # Base error class for all Zenrows errors
  #
  # @author Ernest Bursa
  # @since 0.1.0
  # @api public
  class Error < StandardError; end

  # Raised when configuration is invalid or missing
  #
  # @example
  #   raise Zenrows::ConfigurationError, "API key is required"
  class ConfigurationError < Error; end

  # Raised when API authentication fails (invalid API key)
  #
  # @example
  #   raise Zenrows::AuthenticationError, "Invalid API key"
  class AuthenticationError < Error; end

  # Raised when rate limited (HTTP 429)
  #
  # @example Handling rate limits
  #   begin
  #     response = http.get(url)
  #   rescue Zenrows::RateLimitError => e
  #     sleep(e.retry_after || 60)
  #     retry
  #   end
  class RateLimitError < Error
    # @return [Integer, nil] Seconds to wait before retrying
    attr_reader :retry_after

    # @param message [String] Error message
    # @param retry_after [Integer, nil] Seconds to wait before retrying
    def initialize(message = "Rate limited", retry_after: nil)
      @retry_after = retry_after
      super(message)
    end
  end

  # Raised when bot detection triggers (HTTP 400/403/422)
  #
  # @example
  #   begin
  #     response = http.get(url)
  #   rescue Zenrows::BotDetectedError => e
  #     # Retry with premium proxy
  #     http = client.http(premium_proxy: true, proxy_country: 'us')
  #     response = http.get(url)
  #   end
  class BotDetectedError < Error
    # @return [String, nil] Suggested fix command
    attr_reader :suggestion

    # @param message [String] Error message
    # @param suggestion [String, nil] Suggested fix
    def initialize(message = "Bot detected", suggestion: nil)
      @suggestion = suggestion
      super(message)
    end
  end

  # Raised when request times out
  class TimeoutError < Error; end

  # Raised when proxy connection fails
  class ProxyError < Error; end

  # Raised when wait time exceeds maximum (180 seconds)
  class WaitTimeError < Error; end
end
