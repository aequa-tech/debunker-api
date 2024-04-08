# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        @user = User.new(user_params)
        unless @user.save
          render json: { error: I18n.t('api.messages.user.error.create', errors: @user.errors.full_messages.join(', ')) },
                status: :unprocessable_entity
          return
        end

        SendConfirmationInstructionJob.perform_async(@user.id)
        render json: { success: I18n.t('api.messages.user.success.create') }, status: :ok
      end

      def confirm
        @user = User.find_by(confirmation_token: params[:token])
        if @user.blank?
          return render json: { error: I18n.t('api.messages.user.error.confirm.invalid_token') }, status: :unauthorized
        end

        unless @user.confirm
          render json: { error: I18n.t('api.messages.user.error.confirm.generic',
                                      errors: @user.errors.full_messages.join(', ')) },
                status: :unprocessable_entity
          return
        end

        SendAccountActivatedJob.perform_async(@user.id)
        render json: { user: @user.info_attributes, success: I18n.t('api.messages.user.success.confirm') }, status: :ok
      end

      private

      def user_params
        params.permit(:name, :email, :password, :password_confirmation)
      end

      def include_for_html
        return unless request.format.html?

        self.class.include ActionView::Layouts
        self.class.include ActionController::Rendering
      end
    end
  end
end
