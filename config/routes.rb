# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :registrations, only: %i[create confirm], format: :json do
        collection do
          post :create
          post :confirm
        end
      end

      resources :users, only: %i[status], format: :json do
        collection do
          get :status
        end
      end

      resources :debunk, only: %i[create], format: :json
    end
  end
end
