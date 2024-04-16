# frozen_string_literal: true

require 'rest-client'

module DebunkerAequatech
  module V1
    # API for debunking URLs
    class Api
      METRICS = %w[danger sensationalism echo_effect reliability].freeze

      attr_reader :base_url, :url, :callback_url, :token
      attr_accessor :request_id

      def initialize(url)
        @base_url = ENV.fetch('DEBUNKER_API_V1_URL')
        @url = url
      end

      def debunk
        final_payload = {}
        response = scrape
        payload = JSON.parse(response.body)
        return [{ message: payload['message'] }, payload['status']] unless payload['status'] == 200

        final_payload['scrape'] = payload['result']
        self.request_id = payload['result']['request_id']
        METRICS.each do |metric|
          final_payload[metric] = JSON.parse(send(metric, request_id))['result']
        end

        [final_payload, 200]
      rescue RestClient::ExceptionWithResponse => e
        [JSON.parse(e.response.body), e.response.code]
      end

      private

      def scrape
        RestClient.post([base_url, 'scrape'].join('/') + "?url=#{url}", {})
      end

      def danger(request_id)
        RestClient.get([base_url, 'danger', request_id].join('/'))
      end

      def sensationalism(request_id)
        RestClient.get([base_url, 'sensationalism', request_id].join('/'))
      end

      def echo_effect(request_id)
        RestClient.get([base_url, 'echo_effect', request_id].join('/'))
      end

      def reliability(request_id)
        RestClient.get([base_url, 'reliability', request_id].join('/'))
      end
    end
  end
end
