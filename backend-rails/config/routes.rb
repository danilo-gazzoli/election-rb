# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      get 'auth/session', to: 'auth#show'
      get 'admin/elections', to: 'admin/elections#index'
      post 'admin/elections', to: 'admin/elections#create'
      get 'admin/elections/:id', to: 'admin/elections#show'
      patch 'admin/elections/:id', to: 'admin/elections#update'
      post 'admin/elections/:id/preview', to: 'admin/elections#preview'
      get 'admin/elections/:election_id/parties', to: 'admin/parties#index'
      post 'admin/elections/:election_id/parties', to: 'admin/parties#create'
      patch 'admin/elections/:election_id/parties/:id', to: 'admin/parties#update'
      delete 'admin/elections/:election_id/parties/:id', to: 'admin/parties#destroy'
      post 'admin/elections/:election_id/contests', to: 'admin/contests#create'
      post 'admin/elections/:election_id/voting-devices', to: 'admin/voting_devices#create'
      post 'admin/rounds/:id/open', to: 'admin/rounds#open'
      post 'admin/rounds/:id/suspend', to: 'admin/rounds#suspend'
      post 'admin/rounds/:id/resume', to: 'admin/rounds#resume'
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
