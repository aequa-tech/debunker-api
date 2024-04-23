# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :users do
        get :status,
            format: :json,
            to: '/debunker_assistant/v1/api/users#status'
      end

      post :scrape,
           format: :json,
           to: '/debunker_assistant/v1/api/scrape#create'
    end
  end
end
