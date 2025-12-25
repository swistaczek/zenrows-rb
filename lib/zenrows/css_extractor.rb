# frozen_string_literal: true

require "json"

module Zenrows
  # DSL for building CSS extraction rules
  #
  # Provides a clean interface for defining CSS selectors to extract
  # data from web pages using the ZenRows API.
  #
  # @example Basic extraction
  #   extractor = Zenrows::CssExtractor.build do
  #     extract :title, 'h1'
  #     extract :description, 'meta[name="description"]', attribute: 'content'
  #   end
  #
  # @example With attribute extraction
  #   extractor = Zenrows::CssExtractor.build do
  #     extract :links, 'a.product-link', attribute: 'href'
  #     extract :images, 'img.product-image', attribute: 'src'
  #   end
  #
  # @example Using with ApiClient
  #   api = Zenrows::ApiClient.new
  #   response = api.get(url, css_extractor: extractor)
  #   response.extracted  # => { "title" => "...", "links" => [...] }
  #
  # @author Ernest Bursa
  # @since 0.2.0
  # @api public
  class CssExtractor
    # @return [Hash{Symbol => String}] Extraction rules
    attr_reader :rules

    # Build extractor using DSL block
    #
    # @yield [extractor] Block for defining extraction rules
    # @return [CssExtractor] Configured extractor
    def self.build(&block)
      new.tap { |e| e.instance_eval(&block) }
    end

    # Initialize empty extractor
    def initialize
      @rules = {}
    end

    # Define extraction rule
    #
    # @param name [Symbol, String] Key for extracted data
    # @param selector [String] CSS selector
    # @param attribute [String, nil] Attribute to extract (nil for text content)
    # @return [self] For chaining
    #
    # @example Extract text content
    #   extract :title, 'h1'
    #
    # @example Extract attribute
    #   extract :link, 'a.main', attribute: 'href'
    def extract(name, selector, attribute: nil)
      @rules[name.to_sym] = attribute ? "#{selector} @#{attribute}" : selector
      self
    end

    # Add rule for extracting href attributes
    #
    # @param name [Symbol, String] Key for extracted data
    # @param selector [String] CSS selector for anchor elements
    # @return [self] For chaining
    def links(name, selector)
      extract(name, selector, attribute: "href")
    end

    # Add rule for extracting src attributes
    #
    # @param name [Symbol, String] Key for extracted data
    # @param selector [String] CSS selector for elements with src
    # @return [self] For chaining
    def images(name, selector)
      extract(name, selector, attribute: "src")
    end

    # Convert to hash
    #
    # @return [Hash{Symbol => String}] Rules hash
    def to_h
      @rules
    end

    # Convert to JSON string for API
    #
    # @return [String] JSON representation
    def to_json(*)
      @rules.transform_keys(&:to_s).to_json
    end

    # Check if extractor has rules
    #
    # @return [Boolean]
    def empty?
      @rules.empty?
    end

    # Number of extraction rules
    #
    # @return [Integer]
    def size
      @rules.size
    end
  end
end
