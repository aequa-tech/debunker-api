# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| 'https://github.com/#{repo}.git' }

ruby '3.1.4'
gem 'rails', '~> 7.0.8', '>= 7.0.8.1'

gem 'pg'
gem 'puma', '~> 5.0'
gem 'bcrypt', '~> 3.1.7'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'bootsnap', require: false
gem 'interactor'
gem 'jwt'
gem 'rack-attack'
gem 'rest-client', '~> 2.1'
gem 'sidekiq'
gem 'slim-rails'
gem 'stackprof'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'dotenv-rails'
gem 'overcommit', '~> 0.60.0'
gem 'whenever', require: false
gem 'lograge'
gem "logstash-event"

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'bundler-audit'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'rubocop', require: false
end
