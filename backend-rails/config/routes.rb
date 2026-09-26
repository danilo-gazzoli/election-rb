# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
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
