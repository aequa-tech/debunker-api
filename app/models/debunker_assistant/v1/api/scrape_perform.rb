# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # API for debunking URLs and performing analysis
      # Expect a valid payload
      class ScrapePerform
        include Common

        attr_reader :payload

        def initialize(payload, token_value)
          @base_url = ENV.fetch('DEBUNKER_API_V1_URL')

          @incoming_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(payload)
          @token = Token.find_by(value: token_value)
          @support_response_object = init_support_response_object(@incoming_payload, @token)
        end

        def scrape
          @request_id = @support_response_object[:scrape][:request_id] || llm_scrape
          return perform_outcome unless @request_id

          store_scrape_success(@request_id)

          llm_evaluation
          llm_explanations
          perform_outcome
        end

        private

        def llm_scrape
          response = RestClient.post([@base_url, 'scrape'].join('/') + "?#{scrape_params}", {})
          payload = parse_json(response.body)
          return payload[:result][:request_id] if success_status?(payload[:status])

          payload.is_a?(Hash) ? store_fail_all(payload[:message], payload[:status] || 500) : store_fail_all(payload, 500)
        rescue Errno::ECONNREFUSED,
               RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          store_fail_all(I18n.t("api.messages.errors.#{e.class.to_s.underscore}"), e.try(:http_code) || 500)
        end

        def llm_evaluation
          return if must_skip_analysis?(:evaluation)

          response = RestClient.get([@base_url, 'evaluation'].join('/') + "?#{evaluation_params(@request_id)}")
          payload = parse_json(response.body)

          unless payload.is_a?(Hash) && payload[:analysisId]
            payload.is_a?(Hash) ? store_fail(:evaluation, payload[:message], payload[:status] || 500) : store_fail(:evaluation, payload, 500)
            return
          end

          evaluation_status = evaluation_complete?(payload) ? 200 : incomplete_status
          store_evaluation_success(payload[:analysisId], payload.except(:analysisId), evaluation_status)
        rescue Errno::ECONNREFUSED,
               RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          store_fail(:evaluation, I18n.t("api.messages.errors.#{e.class.to_s.underscore}"),
                     e.try(:http_code) || 500)
        end

        def llm_explanations; end

        def must_skip_analysis?(analysis_type)
          success_status?(@support_response_object[analysis_type.to_sym][:analysis_status])
        end

        def store_scrape_success(request_id)
          @support_response_object[:scrape][:request_id] = request_id
          @token.temporary_response!(@support_response_object.to_json)
          true
        end

        def store_evaluation_success(analysis_id, data, status)
          @support_response_object[:evaluation][:analysis_id] = analysis_id
          @support_response_object[:evaluation][:data] = data
          @support_response_object[:evaluation][:analysis_status] = status
          @support_response_object[:evaluation][:callback_status] = 0
          @token.temporary_response!(@support_response_object.to_json)
          true
        end

        def store_fail(analysis_type, message, status)
          @support_response_object[analysis_type][:data] = { message: }
          @support_response_object[analysis_type][:analysis_status] = status
          @support_response_object[analysis_type][:callback_status] = 0
          @token.temporary_response!(@support_response_object.to_json)
          false
        end

        def store_fail_all(message, status)
          @incoming_payload.analysis_types.each_key do |analysis_type|
            store_fail(analysis_type, message, status)
          end
          false
        end

        def perform_outcome
          return :failure unless @support_response_object[:scrape][:request_id].present?
          return :incomplete_evaluation if @support_response_object[:evaluation][:analysis_status] == incomplete_status

          success = @incoming_payload.analysis_types.keys.map do |analysis_type|
            success_status?(@support_response_object[analysis_type][:analysis_status])
          end.all?
          success ? :success : :failure
        end

        def evaluation_complete?(payload)
          complete = true

          payload.except(:analysisId).each_key do |key|
            next unless complete

            complete = success_status?(payload[key][:status])
          end

          complete
        end

        def scrape_params
          params = ["inputUrl=#{@incoming_payload.url}"]
          params << ["language=#{@incoming_payload.content_language}"]
          params << ["retry=#{@incoming_payload.retry}"]
          params << ["maxRetries=#{@incoming_payload.max_retries}"]
          params << ["timeout=#{@incoming_payload.timeout}"]
          params << ["maxChars=#{@incoming_payload.max_chars}"]
          params.join('&')
        end

        def evaluation_params(request_id)
          "request_id=#{request_id}"
        end
      end
    end
  end
end
