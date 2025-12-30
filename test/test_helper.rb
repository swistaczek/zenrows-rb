# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "zenrows"

require "minitest/autorun"
require "webmock/minitest"

# Simple mock helper for tests
class MockResponse
  attr_reader :status, :headers

  def initialize(status, headers = {})
    @status = status
    @headers = headers
  end
end

class MockHttpClient
  attr_reader :calls

  def initialize
    @calls = []
    @responses = {}
  end

  def stub_response(method, url, response)
    @responses[[method, url]] = response
  end

  def get(url, **options)
    @calls << [:get, url, options]
    @responses[[:get, url]] || MockResponse.new(200)
  end

  def post(url, **options)
    @calls << [:post, url, options]
    @responses[[:post, url]] || MockResponse.new(200)
  end

  def respond_to?(method, include_private = false)
    [:get, :post, :custom_method].include?(method) || super
  end

  def custom_method(*args)
    @calls << [:custom_method, *args]
    :result
  end
end
