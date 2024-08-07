Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN') { '' }
  config.environment = ENV.fetch('SENTRY_ENVIRONMENT') { 'production' }
  config.enabled_environments = %w[staging production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 0
  # or
  # config.traces_sampler = lambda do |context|
  #   true
  # end
  # Set profiles_sample_rate to profile 100%
  # of sampled transactions.
  # We recommend adjusting this value in production.
  config.profiles_sample_rate = 0
end
