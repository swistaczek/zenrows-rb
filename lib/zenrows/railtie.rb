# frozen_string_literal: true

module Zenrows
  # Rails integration for Zenrows
  #
  # Provides Rails-specific features:
  # - ActiveSupport::Duration support for wait times
  # - Rails logger integration
  #
  # @author Ernest Bursa
  # @since 0.1.0
  class Railtie < Rails::Railtie
    initializer "zenrows.configure_rails_initialization" do
      # Set Rails logger as default if not configured
      Zenrows.configure do |config|
        config.logger ||= Rails.logger
      end
    end

    # Generator for creating initializer
    generators do
      require_relative "generators/zenrows/install_generator" if defined?(Rails::Generators)
    end
  end
end
