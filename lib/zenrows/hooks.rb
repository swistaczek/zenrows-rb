# frozen_string_literal: true

require "monitor"

module Zenrows
  # Thread-safe hook registry for request lifecycle events
  #
  # Manages registration and execution of callbacks for HTTP request events.
  # Supports both block-based callbacks and subscriber objects.
  #
  # @example Register a block callback
  #   hooks = Zenrows::Hooks.new
  #   hooks.register(:on_response) { |response, context| puts response.status }
  #
  # @example Register a subscriber object
  #   class MySubscriber
  #     def on_response(response, context)
  #       puts response.status
  #     end
  #   end
  #   hooks.add_subscriber(MySubscriber.new)
  #
  # @author Ernest Bursa
  # @since 0.3.0
  # @api public
  class Hooks
    include MonitorMixin

    # Available hook events
    EVENTS = %i[before_request after_request on_response on_error around_request].freeze

    def initialize
      super # Initialize MonitorMixin
      @callbacks = Hash.new { |h, k| h[k] = [] }
      @subscribers = []
    end

    # Register a callback for an event
    #
    # @param event [Symbol] Event name (:before_request, :after_request, :on_response, :on_error, :around_request)
    # @param callable [#call, nil] Callable object (proc, lambda, or object responding to #call)
    # @yield Block to execute when event fires
    # @return [self] Returns self for chaining
    # @raise [ArgumentError] if event is unknown or handler doesn't respond to #call
    #
    # @example With block
    #   hooks.register(:on_response) { |response, ctx| log(response) }
    #
    # @example With callable
    #   hooks.register(:on_response, ->(response, ctx) { log(response) })
    def register(event, callable = nil, &block)
      validate_event!(event)
      handler = callable || block
      raise ArgumentError, "Handler must respond to #call" unless handler.respond_to?(:call)

      synchronize { @callbacks[event] << handler }
      self
    end

    # Add a subscriber object that responds to hook methods
    #
    # Subscriber objects can implement any of the hook methods:
    # - before_request(context)
    # - after_request(context)
    # - on_response(response, context)
    # - on_error(error, context)
    # - around_request(context, &block)
    #
    # @param subscriber [Object] Object responding to one or more hook methods
    # @return [self] Returns self for chaining
    #
    # @example
    #   class MetricsSubscriber
    #     def on_response(response, context)
    #       StatsD.increment('requests')
    #     end
    #   end
    #   hooks.add_subscriber(MetricsSubscriber.new)
    def add_subscriber(subscriber)
      unless EVENTS.any? { |e| subscriber.respond_to?(e) }
        warn "ZenRows: Subscriber #{subscriber.class} doesn't respond to any hook events"
      end
      synchronize { @subscribers << subscriber }
      self
    end

    # Run callbacks for an event
    #
    # @param event [Symbol] Event name
    # @param args [Array] Arguments to pass to callbacks
    # @return [void]
    def run(event, *args)
      handlers, subscribers = synchronize do
        [@callbacks[event].dup, @subscribers.dup]
      end

      # Run registered callbacks
      handlers.each { |h| h.call(*args) }

      # Run subscriber methods
      subscribers.each do |sub|
        sub.public_send(event, *args) if sub.respond_to?(event)
      end
    end

    # Run around callbacks (wrapping)
    #
    # Executes a chain of around handlers, each wrapping the next.
    # If no around handlers exist, simply yields to the block.
    #
    # @param context [Hash] Request context
    # @yield Block to wrap (the actual HTTP request)
    # @return [Object] Result of the wrapped block
    def run_around(context, &block)
      handlers, subscribers = synchronize do
        [@callbacks[:around_request].dup, @subscribers.dup]
      end

      # Build chain of around handlers
      chain = handlers + subscribers.select { |s| s.respond_to?(:around_request) }

      if chain.empty?
        block.call
      else
        execute_chain(chain, context, &block)
      end
    end

    # Check if any hooks are registered
    #
    # @return [Boolean] true if no hooks registered
    def empty?
      synchronize { @callbacks.values.all?(&:empty?) && @subscribers.empty? }
    end

    # Merge hooks from another registry
    #
    # Used for per-client hooks that inherit from global hooks.
    #
    # @param other [Hooks, nil] Another hooks registry to merge
    # @return [self]
    def merge(other)
      return self unless other

      synchronize do
        EVENTS.each do |event|
          @callbacks[event].concat(other.callbacks_for(event))
        end
        @subscribers.concat(other.subscribers_list)
      end
      self
    end

    # Duplicate the hooks registry
    #
    # @return [Hooks] New hooks registry with copied callbacks
    def dup
      copy = Hooks.new
      synchronize do
        EVENTS.each { |e| @callbacks[e].each { |h| copy.register(e, h) } }
        @subscribers.each { |s| copy.add_subscriber(s) }
      end
      copy
    end

    protected

    # Get callbacks for a specific event (for merging)
    #
    # @param event [Symbol] Event name
    # @return [Array] Copy of callbacks for the event
    def callbacks_for(event)
      synchronize { @callbacks[event].dup }
    end

    # Get subscribers list (for merging)
    #
    # @return [Array] Copy of subscribers
    def subscribers_list
      synchronize { @subscribers.dup }
    end

    private

    # Validate event name
    #
    # @param event [Symbol] Event name
    # @raise [ArgumentError] if event is unknown
    def validate_event!(event)
      return if EVENTS.include?(event)

      raise ArgumentError, "Unknown event: #{event}. Valid events: #{EVENTS.join(", ")}"
    end

    # Execute chain of around handlers
    #
    # @param chain [Array] Array of around handlers
    # @param context [Hash] Request context
    # @yield Block to wrap
    # @return [Object] Result of the wrapped block
    def execute_chain(chain, context, &block)
      chain.reverse.reduce(block) do |next_block, handler|
        lambda {
          if handler.respond_to?(:around_request)
            handler.around_request(context, &next_block)
          else
            handler.call(context, &next_block)
          end
        }
      end.call
    end
  end
end
