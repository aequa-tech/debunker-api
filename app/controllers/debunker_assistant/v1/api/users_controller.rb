# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Controller responsible for handling user status API requests in the V1 namespace.
      class UsersController < RequestController
        before_action :ensure_admin, only: %i[index show update create destroy]

        def index
          @users = User.all
          render json: @users, status: :ok
        end

        def show
          @user = User.find(params[:id])
          render json: @user, status: :ok
        end

        def update
          @user = User.find(params[:id])
          @params = JSON.parse(request.body.read).deep_symbolize_keys

          if @user.update(@params[:user])
            render json: @user, status: :ok
          else
            render json: { errors: @user.errors }, status: :unprocessable_entity
          end
        end

        def create
          @user = User.new(JSON.parse(request.body.read).deep_symbolize_keys[:user])

          if @user.save
            render json: @user, status: :created
          else
            render json: { errors: @user.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          @user = User.find(params[:id])

          if @user.destroy
            render json: { message: I18n.t('api.messages.user.destroyed') }, status: :ok
          else
            render json: { errors: @user.errors }, status: :unprocessable_entity
          end
        end

        def status
          render json: {
            user: api_key.user.info_attributes,
            available_tokens: api_key.available_tokens.count
          }, status: :ok
        end
      end
    end
  end
end
