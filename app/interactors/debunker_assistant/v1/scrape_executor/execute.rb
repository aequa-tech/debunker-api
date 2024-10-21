# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeExecutor
      class Execute
        include Interactor

        before :prepare_context

        def call
          return end_process if retry_status == :no_retry

          unless exceeded?(process: :perform)
            perform
            return fail_with_retry! if must_retry?(process: :perform)
          end

          unless exceeded?(process: :callback)
            callback
            return fail_with_retry! if must_retry?(process: :callback)
          end

          # incomplete evaluation
          return fail_with_retry! if first_incomplete_evaluation?

          end_process
        end

        private

        def perform
          context.token.increase_retries!(kind: :perform) and context.token.reload
          context.result_perform = perform_call

          if context.result_perform == :incomplete_evaluation
            context.token.status!(:incomplete_evaluation,
                                  kind: :perform)
          end

          context.token.reload
        end

        def callback
          context.token.increase_retries!(kind: :callback) and context.token.reload
          context.result_callback = callback_call
        end

        def first_incomplete_evaluation?
          context.from_retry != 'incomplete_evaluation' && context.result_perform == :incomplete_evaluation
        end

        def must_retry?(process:)
          return false if exceeded?(process:)

          negative_result?(result_by_process(process:))
        end

        def negative_result?(result)
          %i[partial failure].include?(result)
        end

        def exceeded?(process:)
          case process
          when :perform then context.token.perform_retries >= context.max_retries
          when :callback then context.token.callback_retries >= context.max_retries
          end
        end

        def result_by_process(process:)
          case process
          when :perform then context.result_perform
          when :callback then context.result_callback
          end
        end

        def prepare_context
          context.max_retries = ENV.fetch('TOKEN_MAX_RETRIES').to_i
          context.token = Token.find_by(value: context.token_value) || fail_with_retry!
        end

        def retry_status
          return :retry_incomplete_evaluation if context.result_perform == :incomplete_evaluation
          return :no_retry if context.token.blank?

          !retries_exceeded? ? :retry : :no_retry
        end

        def fail_with_retry!
          context.fail!(retry_perform: retry_status)
        end

        def perform_call
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(context.token.value).scrape
        end

        def callback_call
          ::DebunkerAssistant::V1::Api::ScrapeCallback.new(context.token.value).callback
        end

        def end_process
          context.retry_perform = :no_retry

          context.token.reload and context.token.finish!
        end

        def retries_exceeded?
          exceeded?(process: :perform) && exceeded?(process: :callback)
        end
      end
    end
  end
end
