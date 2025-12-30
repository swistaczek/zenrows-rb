# frozen_string_literal: true

require_relative "zenrows/version"
require_relative "zenrows/errors"
require_relative "zenrows/hooks"
require_relative "zenrows/hooks/context"
require_relative "zenrows/hooks/log_subscriber"
require_relative "zenrows/configuration"
require_relative "zenrows/proxy"
require_relative "zenrows/js_instructions"
require_relative "zenrows/instrumented_client"
require_relative "zenrows/backends/base"
require_relative "zenrows/backends/net_http"
begin
  require_relative "zenrows/backends/http_rb"
rescue LoadError
  # http.rb not available, will use net_http fallback
end
require_relative "zenrows/client"
require_relative "zenrows/css_extractor"
require_relative "zenrows/api_response"
require_relative "zenrows/api_client"

# ZenRows Ruby client for web scraping proxy
#
# @example Basic configuration and usage
#   Zenrows.configure do |config|
#     config.api_key = 'YOUR_API_KEY'
#   end
#
#   client = Zenrows::Client.new
#   http = client.http(js_render: true, premium_proxy: true)
#   response = http.get('https://example.com')
#
# @example With JavaScript instructions
#   instructions = Zenrows::JsInstructions.build do
#     click '.load-more'
#     wait 2000
#     scroll_to :bottom
#   end
#
#   http = client.http(js_render: true, js_instructions: instructions)
#
# @author Ernest Bursa
# @since 0.1.0
module Zenrows
  class << self
    # @return [Configuration] Global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure Zenrows with a block
    #
    # @example
    #   Zenrows.configure do |config|
    #     config.api_key = 'YOUR_API_KEY'
    #     config.host = 'superproxy.zenrows.com'
    #     config.port = 1337
    #   end
    #
    # @yield [Configuration] configuration instance
    # @return [Configuration] configuration instance
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Reset configuration to defaults
    #
    # @return [void]
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

# Optional Rails integration
require_relative "zenrows/railtie" if defined?(Rails::Railtie)
