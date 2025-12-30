# frozen_string_literal: true

module Zenrows
  class Hooks
    # Built-in logging subscriber for ZenRows requests
    #
    # Logs request lifecycle events using a configurable logger.
    # Uses lazy evaluation (blocks) to avoid string interpolation overhead
    # when log level is not enabled.
    #
    # @example Basic usage
    #   Zenrows.configure do |c|
    #     c.logger = Logger.new(STDOUT)
    #     c.add_subscriber(Zenrows::Hooks::LogSubscriber.new)
    #   end
    #
    # @example With custom logger
    #   subscriber = Zenrows::Hooks::LogSubscriber.new(logger: Rails.logger)
    #   Zenrows.configure { |c| c.add_subscriber(subscriber) }
    #
    # @author Ernest Bursa
    # @since 0.3.0
    # @api public
    class LogSubscriber
      # @return [Logger, nil] Logger instance
      attr_reader :logger

      # Create a new log subscriber
      #
      # @param logger [Logger, nil] Logger instance. If nil, uses Zenrows.configuration.logger
      def initialize(logger: nil)
        @logger = logger
      end

      # Log before request starts
      #
      # @param context [Hash] Request context
      def before_request(context)
        log(:debug) do
          "ZenRows request: #{context[:method].to_s.upcase} #{context[:url]}"
        end
      end

      # Log successful response
      #
      # @param response [Object] HTTP response
      # @param context [Hash] Request context
      def on_response(response, context)
        status = extract_status(response)
        duration = format_duration(context[:duration])
        cost = context.dig(:zenrows_headers, :request_cost)

        message = "ZenRows #{context[:url]} -> #{status}"
        message += " (#{duration})" if duration
        message += " [cost: #{cost}]" if cost

        log(:info) { message }
      end

      # Log error
      #
      # @param error [Exception] The error that occurred
      # @param context [Hash] Request context
      def on_error(error, context)
        request_id = context.dig(:zenrows_headers, :request_id)

        message = "ZenRows #{context[:url]} failed: #{error.class} - #{error.message}"
        message += " [request_id: #{request_id}]" if request_id

        log(:error) { message }
      end

      private

      # Get the effective logger
      #
      # @return [Logger, nil] Logger to use
      def effective_logger
        @logger || Zenrows.configuration.logger
      end

      # Log a message at the specified level
      #
      # @param level [Symbol] Log level (:debug, :info, :warn, :error)
      # @yield Block returning the message to log
      def log(level, &block)
        return unless effective_logger

        if effective_logger.respond_to?(level)
          effective_logger.public_send(level, &block)
        end
      end

      # Extract status from response object
      #
      # @param response [Object] HTTP response
      # @return [String] Status string
      def extract_status(response)
        if response.respond_to?(:status)
          status = response.status
          status.respond_to?(:code) ? status.code : status.to_s
        elsif response.respond_to?(:code)
          response.code
        else
          "unknown"
        end
      end

      # Format duration for display
      #
      # @param duration [Float, nil] Duration in seconds
      # @return [String, nil] Formatted duration
      def format_duration(duration)
        return nil unless duration

        if duration < 1
          "#{(duration * 1000).round}ms"
        else
          "#{duration.round(2)}s"
        end
      end
    end
  end
end
