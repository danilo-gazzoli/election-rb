# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      get 'auth/session', to: 'auth#show'
      post 'admin/elections/:election_id/voting-devices', to: 'admin/voting_devices#create'
      post 'admin/rounds/:id/open', to: 'admin/rounds#open'
      post 'admin/rounds/:id/close', to: 'admin/rounds#close'
      post 'voting-device/pair', to: 'voting_device#pair'
      get 'voting-device/state', to: 'voting_device#state'
      post 'voting-device/confirmations', to: 'voting_device#confirm'
      post 'pollworker/voting-devices/:id/release', to: 'pollworker/voting_devices#release'
      post 'pollworker/sessions/:id/abandon', to: 'pollworker/sessions#abandon'
      get 'public/elections/:id/partial', to: 'public/elections#partial'
      get 'health', to: 'health#show'
      match '*unmatched', to: 'errors#not_found', via: :all
    end
  end

  resources :elections
  resources :offices
  resources :parties
  resources :candidates
  get 'up' => 'rails/health#show', as: :rails_health_check
end
