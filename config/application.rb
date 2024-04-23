# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
Dotenv::Railtie.load

module DebunkerApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    Dir.glob("#{Rails.root}/lib/**/*.rb").each do |file|
      require file
    end

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.i18n.default_locale = :it
    config.i18n.available_locales = %i[it en]

    # We are going to use the Rack::Attack middleware to throttle the requests
    # to the API. We are going to throttle the requests to 5 requests per minute (initializers/rack_attack.rb).
    config.middleware.use Rack::Attack
    # We are going to add the ResponseHeaders middleware to add the Content-Length and RateLimit headers to responses
    # and remove all headers except Content-Type (lib/debunker_assistant/v1/middleware/response_headers.rb).
    # it is important to add this middleware before the ActionDispatch::HostAuthorization middleware to avoid
    # other headers being added after this middleware.
    config.middleware.insert_before(
      ActionDispatch::HostAuthorization,
      DebunkerAssistant::V1::Middleware::ResponseHeaders
    )
  end
end
