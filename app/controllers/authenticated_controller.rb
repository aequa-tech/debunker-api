# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    api_key = request.headers['X-Api-Key']
    if api_key.blank?
      return render json: { error: I18n.t('api.messages.user.error.unauthorized') }, status: :unauthorized
    end

    @user = User.find_by(api_key:)
    render json: { error: I18n.t('api.messages.user.error.unauthorized') }, status: :unauthorized if @user.blank?
  end
end
