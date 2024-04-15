# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  private

  def authenticate_user!
    api_key = request.headers['X-API-Key']
    api_secret = request.headers['X-API-Secret']

    unless ApiKey.authenticate!(api_key, api_secret)
      return render json: { error: I18n.t('api.messages.user.error.unauthorized') }, status: :unauthorized
    end

    @user = ApiKey.find_by(access_token: api_key).user
    render json: { error: I18n.t('api.messages.user.error.unauthorized') }, status: :unauthorized if @user.blank?
  end
end
