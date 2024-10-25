# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Set up the API payload for the Debunker Assistant API V1
      # with default values where necessary
      class ScrapePayload
        include ActiveModel::Model

        attr_accessor :url, :analysis_types, :content_language, :retry, :max_retries,
                      :timeout, :max_chars, :raw

        validate :url_validation, :analysis_types_validation, :evaluation_or_explanations_presence,
                 :evaluation_validation, :explanations_validation, :content_language_validation,
                 :retry_validation, :max_retries_validation, :timeout_validation, :max_chars_validation

        def initialize(json)
          self.raw = json
          parsed = JSON.parse(json.to_s).deep_transform_keys(&:underscore).deep_symbolize_keys
          assign_attributes(parsed)
          set_default_values
          unescape_urls
        rescue JSON::ParserError, NoMethodError
          errors.add(:base, :invalid_json)
        end

        private

        def set_default_values
          self.url = '' if url.blank?
          self.analysis_types = {} if analysis_types.blank?
          self.content_language = I18n.default_locale.to_s if content_language.blank?
          set_missing_values_from_env
        end

        def set_missing_values_from_env
          %w[retry max_retries timeout max_chars].each do |key|
            send("#{key}=", ENV.fetch("API_V1_DEFAULTS_#{key.upcase}")) if send(key).blank?
          end
        end

        def unescape_urls
          self.url = CGI.unescape(url.to_s)
          %i[evaluation explanations].each do |key|
            next unless analysis_types.is_a?(Hash)
            next if analysis_types[key].blank?

            analysis_types[key][:callback_url] = CGI.unescape(analysis_types[key][:callback_url].to_s)
          end
        end

        def url_validation
          return errors.add(:base, :url_blank) if url.blank?
          return if valid_uri?(url)

          errors.add(:base, :invalid_url)
        end

        def analysis_types_validation
          return errors.add(:base, :analysis_types_blank) if analysis_types.blank?

          errors.add(:base, :analysis_types_invalid) unless analysis_types.is_a?(Hash)
        end

        def content_language_validation
          return if content_language.blank?
          return if I18n.available_locales.map(&:to_s).include?(content_language)

          errors.add(:base, :content_language_invalid)
        end

        def retry_validation
          return if self.retry.blank?
          return if %w[true false].include?(self.retry)

          errors.add(:base, :retry_invalid)
        end

        def max_retries_validation
          return if max_retries.blank?

          value = Integer(max_retries)
          return if value >= 0 && value <= ENV.fetch('API_V1_MAXIMUM_MAX_RETRIES').to_i

          errors.add(:base, :max_retries_invalid)
        rescue ArgumentError
          errors.add(:base, :max_retries_invalid)
        end

        def timeout_validation
          return if timeout.blank?

          value = Integer(timeout)
          return if value >= 0 && value <= ENV.fetch('API_V1_MAXIMUM_TIMEOUT').to_i

          errors.add(:base, :timeout_invalid)
        rescue ArgumentError
          errors.add(:base, :timeout_invalid)
        end

        def max_chars_validation
          return if max_chars.blank?

          value = Integer(max_chars)
          return if value >= 0 && value <= ENV.fetch('API_V1_MAXIMUM_MAX_CHARS').to_i

          errors.add(:base, :max_chars_invalid)
        rescue ArgumentError
          errors.add(:base, :max_chars_invalid)
        end

        def evaluation_or_explanations_presence
          return if analysis_types.blank?
          return unless analysis_types.is_a?(Hash)
          return if analysis_types[:evaluation].present? || analysis_types[:explanations].present?

          errors.add(:base, :evaluation_or_explanations)
        end

        def evaluation_validation
          return if analysis_types.blank?
          return unless analysis_types.is_a?(Hash)
          return if analysis_types[:evaluation].blank?
          return errors.add(:base, :evaluation_callback_blank) if analysis_types[:evaluation][:callback_url].blank?
          return if valid_uri?(analysis_types[:evaluation][:callback_url])

          errors.add(:base, :evaluation_callback_invalid)
        end

        def explanations_validation
          return if analysis_types.blank?
          return unless analysis_types.is_a?(Hash)
          return if analysis_types[:explanations].blank?
          return errors.add(:base, :explanations_callback_blank) if analysis_types[:explanations][:callback_url].blank?

          unless valid_uri?(analysis_types[:explanations][:callback_url])
            return errors.add(:base, :explanations_callback_invalid)
          end

          if analysis_types[:explanations][:explanation_types].blank?
            return errors.add(:base, :explanations_explanation_types_blank)
          end

          explanation_types = ENV.fetch('API_V1_PERMITTED_EXPLANATIONS').split(',')
          return if (analysis_types[:explanations][:explanation_types].map(&:to_s) - explanation_types).empty?

          errors.add(:base, :explanations_explanation_types_invalid)
        end

        def valid_uri?(url)
          return false if url.blank?
          return false unless url.is_a?(String)
          return false unless url.start_with?('http://') || url.start_with?('https://')

          uri = URI.parse(url)
          uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end
