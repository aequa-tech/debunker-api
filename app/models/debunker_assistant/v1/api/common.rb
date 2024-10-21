# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      module Common
        include ::Utils

        private

        def set_base_uri_parts
          @base_uri = URI.parse(ENV.fetch('DEBUNKER_API_V1_URL'))
          @base_host = @base_uri.host
          @base_path = @base_uri.path
          @base_port = @base_uri.port
          @base_scheme = @base_uri.scheme
        end

        def post_call(parametrized_path, payload)
          http = Net::HTTP.new(@base_host, @base_port)
          http.use_ssl = @base_scheme == 'https'

          request = Net::HTTP::Post.new(parametrized_path)
          if (ENV.fetch('DEBUNKER_API_USERNAME', nil) && ENV.fetch('DEBUNKER_API_PASSWORD', nil)).present?
            request.basic_auth(ENV.fetch('DEBUNKER_API_USERNAME'), ENV.fetch('DEBUNKER_API_PASSWORD'))
          end
          request.body = payload.to_json if payload.present?

          http.request(request)
        end

        def get_call(parametrized_path)
          http = Net::HTTP.new(@base_host, @base_port)
          http.use_ssl = @base_scheme == 'https'

          request = Net::HTTP::Get.new(parametrized_path)
          if (ENV.fetch('DEBUNKER_API_USERNAME', nil) && ENV.fetch('DEBUNKER_API_PASSWORD', nil)).present?
            request.basic_auth(ENV.fetch('DEBUNKER_API_USERNAME'), ENV.fetch('DEBUNKER_API_PASSWORD'))
          end

          http.request(request)
        end
      end
    end
  end
end
