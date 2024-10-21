# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Controller responsible for handling user status API requests in the V1 namespace.
      class RolesController < RequestController
        before_action :ensure_admin, only: %i[index show update create destroy]

        def index
          @roles = Role.all
          render json: @roles, status: :ok
        end

        def show
          @role = Role.find(params[:id])
          render json: @role, status: :ok
        end

        def update
          @role = Role.find(params[:id])
          @params = JSON.parse(request.body.read).deep_symbolize_keys

          if @role.update(@params[:role])
            render json: @role, status: :ok
          else
            render json: { errors: @role.errors }, status: :unprocessable_entity
          end
        end

        def create
          @role = Role.new(JSON.parse(request.body.read).deep_symbolize_keys[:role])

          if @role.save
            render json: @role, status: :created
          else
            render json: { errors: @role.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          @role = Role.find(params[:id])

          if @role.destroy
            render json: { message: I18n.t('api.messages.role.destroyed') }, status: :ok
          else
            render json: { errors: @role.errors }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
