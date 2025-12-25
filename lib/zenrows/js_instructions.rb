# frozen_string_literal: true

require "json"

module Zenrows
  # DSL for building JavaScript instructions
  #
  # JavaScript instructions enable dynamic interaction with web pages
  # by automating user actions like clicking, filling forms, scrolling,
  # and executing custom JavaScript.
  #
  # @example Building instructions with DSL
  #   instructions = Zenrows::JsInstructions.build do
  #     click '.load-more'
  #     wait 2000
  #     fill 'input#email', 'test@example.com'
  #     scroll_to :bottom
  #     wait_for '.results'
  #   end
  #
  # @example Using with client
  #   client = Zenrows::Client.new
  #   http = client.http(
  #     js_render: true,
  #     js_instructions: instructions
  #   )
  #
  # @author Ernest Bursa
  # @since 0.1.0
  # @api public
  class JsInstructions
    # @return [Array<Hash>] List of instructions
    attr_reader :instructions

    def initialize
      @instructions = []
    end

    # Build instructions using DSL block
    #
    # @yield [JsInstructions] Builder instance
    # @return [JsInstructions] Built instructions
    #
    # @example
    #   Zenrows::JsInstructions.build do
    #     click '.button'
    #     wait 1000
    #   end
    def self.build(&block)
      builder = new
      builder.instance_eval(&block) if block
      builder
    end

    # Click an element
    #
    # @param selector [String] CSS selector
    # @return [self]
    #
    # @example
    #   click '.submit-button'
    #   click '#load-more'
    def click(selector)
      @instructions << {click: selector}
      self
    end

    # Wait for a duration in milliseconds
    #
    # @param duration [Integer] Milliseconds to wait (max 10000)
    # @return [self]
    #
    # @example
    #   wait 2000  # Wait 2 seconds
    def wait(duration)
      @instructions << {wait: duration}
      self
    end

    # Wait for an element to appear
    #
    # @param selector [String] CSS selector
    # @return [self]
    #
    # @example
    #   wait_for '.dynamic-content'
    #   wait_for '#results-loaded'
    def wait_for(selector)
      @instructions << {wait_for: selector}
      self
    end

    # Wait for a browser event
    #
    # @param event [String, Symbol] Event name: networkidle, load, domcontentloaded
    # @return [self]
    #
    # @example
    #   wait_event :networkidle
    def wait_event(event)
      @instructions << {wait_event: event.to_s}
      self
    end

    # Fill an input field
    #
    # @param selector [String] CSS selector for input
    # @param value [String] Value to fill
    # @return [self]
    #
    # @example
    #   fill 'input#email', 'user@example.com'
    #   fill 'input[name="password"]', 'secret123'
    def fill(selector, value)
      @instructions << {fill: [selector, value]}
      self
    end

    # Check a checkbox
    #
    # @param selector [String] CSS selector
    # @return [self]
    def check(selector)
      @instructions << {check: selector}
      self
    end

    # Uncheck a checkbox
    #
    # @param selector [String] CSS selector
    # @return [self]
    def uncheck(selector)
      @instructions << {uncheck: selector}
      self
    end

    # Select an option from dropdown
    #
    # @param selector [String] CSS selector for select element
    # @param value [String] Option value to select
    # @return [self]
    #
    # @example
    #   select_option '#country', 'US'
    def select_option(selector, value)
      @instructions << {select_option: [selector, value]}
      self
    end

    # Scroll vertically
    #
    # @param pixels [Integer] Pixels to scroll (negative = up)
    # @return [self]
    #
    # @example
    #   scroll_y 1500   # Scroll down
    #   scroll_y -500   # Scroll up
    def scroll_y(pixels)
      @instructions << {scroll_y: pixels}
      self
    end

    # Scroll horizontally
    #
    # @param pixels [Integer] Pixels to scroll (negative = left)
    # @return [self]
    def scroll_x(pixels)
      @instructions << {scroll_x: pixels}
      self
    end

    # Scroll to position
    #
    # @param position [String, Symbol] :bottom or :top
    # @return [self]
    #
    # @example
    #   scroll_to :bottom
    #   scroll_to :top
    def scroll_to(position)
      @instructions << {scroll_to: position.to_s}
      self
    end

    # Execute custom JavaScript
    #
    # @param code [String] JavaScript code to execute
    # @return [self]
    #
    # @example
    #   evaluate "window.scrollTo(0, document.body.scrollHeight)"
    #   evaluate "document.querySelector('.modal').remove()"
    def evaluate(code)
      @instructions << {evaluate: code}
      self
    end

    # Click element inside iframe
    #
    # @param iframe_selector [String] CSS selector for iframe
    # @param element_selector [String] CSS selector for element inside iframe
    # @return [self]
    def frame_click(iframe_selector, element_selector)
      @instructions << {frame_click: [iframe_selector, element_selector]}
      self
    end

    # Wait for element inside iframe
    #
    # @param iframe_selector [String] CSS selector for iframe
    # @param element_selector [String] CSS selector for element
    # @return [self]
    def frame_wait_for(iframe_selector, element_selector)
      @instructions << {frame_wait_for: [iframe_selector, element_selector]}
      self
    end

    # Fill input inside iframe
    #
    # @param iframe_selector [String] CSS selector for iframe
    # @param input_selector [String] CSS selector for input
    # @param value [String] Value to fill
    # @return [self]
    def frame_fill(iframe_selector, input_selector, value)
      @instructions << {frame_fill: [iframe_selector, input_selector, value]}
      self
    end

    # Execute JavaScript inside iframe
    #
    # @param iframe_name [String] Iframe name or URL
    # @param code [String] JavaScript code
    # @return [self]
    def frame_evaluate(iframe_name, code)
      @instructions << {frame_evaluate: [iframe_name, code]}
      self
    end

    # Convert to JSON string for API
    #
    # @return [String] JSON-encoded instructions
    def to_json(*_args)
      @instructions.to_json
    end

    # Convert to array
    #
    # @return [Array<Hash>] Instructions array
    def to_a
      @instructions.dup
    end

    # Check if there are any instructions
    #
    # @return [Boolean]
    def empty?
      @instructions.empty?
    end

    # Number of instructions
    #
    # @return [Integer]
    def size
      @instructions.size
    end
  end
end
