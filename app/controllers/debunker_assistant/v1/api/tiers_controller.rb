# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      class TiersController < RequestController
        before_action :ensure_admin, only: %i[index show update create destroy]

        def index
          @tiers = Tier.all
          render json: @tiers, status: :ok
        end

        def show
          @tier = Tier.find(params[:id])
          render json: @tier, status: :ok
        end

        def update
          @tier = Tier.find(params[:id])
          @params = JSON.parse(request.body.read).deep_symbolize_keys

          if @tier.update(@params[:tier])
            render json: @tier, status: :ok
          else
            render json: { errors: @tier.errors }, status: :unprocessable_entity
          end
        end

        def create
          @tier = Tier.new(JSON.parse(request.body.read).deep_symbolize_keys[:tier])

          if @tier.save
            render json: @tier, status: :created
          else
            render json: { errors: @tier.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          @tier = Tier.find(params[:id])

          if @tier.destroy
            render json: { message: I18n.t('api.messages.tier.destroyed') }, status: :ok
          else
            render json: { errors: @tier.errors }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
