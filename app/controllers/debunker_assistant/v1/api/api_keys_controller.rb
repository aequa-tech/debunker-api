# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      class ApiKeysController < RequestController
        before_action :ensure_admin, only: %i[index show update create destroy]

        def index
          @api_keys = ApiKey.where(user_id: params[:user_id])
          render json: @api_keys, status: :ok
        end

        def show
          @api_key = ApiKey.where(user_id: params[:user_id]).find(params[:id])
          render json: @api_key, status: :ok
        end

        def create
          @user = User.find(params[:user_id])
          @api_key = @user.api_keys.new(JSON.parse(request.body.read).deep_symbolize_keys[:api_key])

          if @api_key.save
            render json: @api_key, status: :created
          else
            render json: { errors: @api_key.errors }, status: :unprocessable_entity
          end
        end

        def expire
          @api_key = ApiKey.where(user_id: params[:user_id]).find(params[:id])

          if @api_key.update(expired_at: Time.zone.now)
            render json: { message: I18n.t('api.messages.api_key.expired') }, status: :ok
          else
            render json: { errors: @api_key.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          @api_key = ApiKey.where(user_id: params[:user_id]).find(params[:id])

          if @api_key.destroy
            render json: { message: I18n.t('api.messages.api_key.destroyed') }, status: :ok
          else
            render json: { errors: @api_key.errors }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
