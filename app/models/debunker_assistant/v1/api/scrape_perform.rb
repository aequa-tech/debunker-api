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
          set_base_uri_parts
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
          response = post_call([@base_path, 'scrape'].join('/').gsub('//', '/') + "?#{scrape_params}", {})
          payload = parse_json(response.body)

          return store_fail_all(payload, response.code) unless payload.is_a?(Hash)
          return payload[:request_id] if success_status?(response.code)

          store_fail_all(payload[:message], response.code || 500)
        rescue Errno::ECONNREFUSED,
               RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          store_fail_all(I18n.t("api.messages.errors.#{e.class.to_s.underscore}"), e.try(:http_code) || 500)
        end

        def llm_evaluation
          return if must_skip_analysis?(:evaluation)

          response = get_call([@base_path, 'evaluation'].join('/').gsub('//',
                                                                        '/') + "?#{evaluation_params(@request_id)}")
          payload = parse_json(response.body)

          return store_fail(:evaluation, payload, response.code) unless payload.is_a?(Hash)
          return store_fail(:evaluation, payload[:message], response.code || 500) unless payload[:analysis_id]

          evaluation_status = response.code.to_i == incomplete_status ? incomplete_status : 200
          store_evaluation_success(payload[:analysis_id], payload, evaluation_status)
        rescue Errno::ECONNREFUSED,
               RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          store_fail(:evaluation, I18n.t("api.messages.errors.#{e.class.to_s.underscore}"),
                     e.try(:http_code) || 500)
        end

        def llm_explanations
          return if must_skip_analysis?(:explanations)

          @incoming_payload.analysis_types[:explanations][:explanation_types].each do |explanation_type|
            if @support_response_object[:evaluation][:analysis_id].blank?
              store_explanations_fail(explanation_type, I18n.t('api.messages.scrape.error.evaluation'), 400)
              next
            end

            if explanation_type == 'explanationNetworkAnalysis'
              store_explanations_fail(explanation_type, '', 501)
              next
            end

            response = get_call([@base_path, 'explanations'].join('/').gsub('//', '/') +
                                "?#{explanations_params(@support_response_object[:evaluation][:analysis_id],
                                                        explanation_type)}")
            payload = parse_json(response.body)

            unless payload.is_a?(Hash)
              store_explanations_fail(explanation_type, payload, response.code)
              next
            end

            unless success_status?(response.code)
              store_explanations_fail(explanation_type, payload[:message], response.code || 500)
              next
            end

            store_explanations_success(explanation_type, payload.except('explanationDim'))
          rescue Errno::ECONNREFUSED,
                 RestClient::ExceptionWithResponse,
                 RestClient::Exceptions::ReadTimeout,
                 JSON::ParserError => e
            store_explanations_fail(explanation_type, I18n.t("api.messages.errors.#{e.class.to_s.underscore}"),
                                    e.try(:http_code) || 500)
          end
        end

        def must_skip_analysis?(analysis_type)
          return true if @incoming_payload.analysis_types[analysis_type].blank?

          success_status?(@support_response_object[analysis_type.to_sym][:analysis_status])
        end

        def store_scrape_success(request_id)
          @support_response_object[:scrape][:request_id] = request_id
          @token.temporary_response!(@support_response_object.to_json)
          true
        end

        def store_evaluation_success(analysis_id, data, status)
          @support_response_object[:evaluation][:analysis_id] = analysis_id
          @support_response_object[:evaluation][:data] = data.merge(status:)
          @support_response_object[:evaluation][:analysis_status] = status.to_i
          @support_response_object[:evaluation][:callback_status] = 0
          @token.temporary_response!(@support_response_object.to_json)
          true
        end

        def store_fail(analysis_type, message, status)
          message = Rack::Utils::HTTP_STATUS_CODES[status] if message.blank?

          @support_response_object[analysis_type][:data] = { message:, status: }
          @support_response_object[analysis_type][:analysis_status] = status.to_i
          @support_response_object[analysis_type][:callback_status] = 0
          @token.temporary_response!(@support_response_object.to_json)
          false
        end

        def store_explanations_fail(explanation_type, message, status = 500)
          if explanation_type == 'explanationNetworkAnalysis'
            message = 'Network analysis not yet implemented'
            status = 501
          end

          message = Rack::Utils::HTTP_STATUS_CODES[status] if message.blank?

          @support_response_object[:explanations][:data] ||= []
          @support_response_object[:explanations][:data].reject! do |explanation|
            explanation[:explanationDim] == explanation_type
          end
          @support_response_object[:explanations][:data] << { explanationDim: explanation_type, message:,
                                                              status: status.to_i }
          @support_response_object[:explanations][:analysis_status] = @support_response_object[:explanations][:data].map do |explanation|
                                                                        explanation[:status].to_i
                                                                      end.max do |a, b|
            a <=> b
          end
          @support_response_object[:explanations][:callback_status] = 0
          @token.temporary_response!(@support_response_object.to_json)
          false
        end

        def store_explanations_success(explanation_type, payload)
          @support_response_object[:explanations][:data] ||= []
          @support_response_object[:explanations][:data].reject! do |explanation|
            explanation[:explanationDim] == explanation_type
          end
          @support_response_object[:explanations][:data] << { explanationDim: explanation_type, data: payload,
                                                              status: 200 }
          @support_response_object[:explanations][:analysis_status] = @support_response_object[:explanations][:data].map do |explanation|
                                                                        explanation[:status].to_i
                                                                      end.max do |a, b|
            a <=> b
          end
          @support_response_object[:explanations][:callback_status] = 0
          @token.temporary_response!(@support_response_object.to_json)
          true
        end

        def store_fail_all(message, status)
          store_fail(:evaluation, message, status.to_i)
          return false if @incoming_payload.analysis_types[:explanations].blank?

          @incoming_payload.analysis_types[:explanations][:explanation_types].each do |explanation_type|
            store_explanations_fail(explanation_type, message, status.to_i)
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

        def scrape_params
          params = ["inputUrl=#{CGI.escape(@incoming_payload.url)}"]
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

        def explanations_params(analysis_id, explanation_type)
          params = ["analysis_id=#{analysis_id}"]
          params << "explanation_type=#{explanation_type}"
          params.join('&')
        end
      end
    end
  end
end
