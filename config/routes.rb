# frozen_string_literal: true

Rails.application.routes.draw do
  namespaced_path = '/debunker_assistant/v1/api/'

  namespace :api, format: :json do
    namespace :v1 do
      namespace :users do
        get '/', to: "#{namespaced_path}users#index"
        get '/:id', to: "#{namespaced_path}users#show"
        post '/', to: "#{namespaced_path}users#create"
        put '/:id', to: "#{namespaced_path}users#update"
        delete '/:id', to: "#{namespaced_path}users#destroy"

        namespace :api_keys, path: '/:user_id/api_keys' do
          get '/', to: "#{namespaced_path}api_keys#index"
          get '/:id', to: "#{namespaced_path}api_keys#show"
          post '/', to: "#{namespaced_path}api_keys#create"
          put '/:id', to: "#{namespaced_path}api_keys#update"
          delete '/:id', to: "#{namespaced_path}api_keys#destroy"
          post '/:id/expire', to: "#{namespaced_path}api_keys#expire"
        end
      end

      namespace :roles, format: :json do
        get '/', to: "#{namespaced_path}roles#index"
        get '/:id', to: "#{namespaced_path}roles#show"
        post '/', to: "#{namespaced_path}roles#create"
        put '/:id', to: "#{namespaced_path}roles#update"
        delete '/:id', to: "#{namespaced_path}roles#destroy"
      end

      namespace :tiers, format: :json do
        get '/', to: "#{namespaced_path}tiers#index"
        get '/:id', to: "#{namespaced_path}tiers#show"
        post '/', to: "#{namespaced_path}tiers#create"
        put '/:id', to: "#{namespaced_path}tiers#update"
        delete '/:id', to: "#{namespaced_path}tiers#destroy"
      end

      get '/user/status', to: "#{namespaced_path}users#status"
      post '/scrape', to: "#{namespaced_path}scrape#create"
    end
  end
end
