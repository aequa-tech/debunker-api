# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def confirmation_instructions(user)
    @user = user
    @token = user.confirmation_token

    mail(to: @user.email, subject: 'Confirm your email address')
  end

  def account_activated(user)
    @user = user
    @api_key = @user.api_key

    mail(to: @user.email, subject: 'Account confirmed')
  end
end
