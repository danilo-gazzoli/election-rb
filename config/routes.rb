# frozen_string_literal: true

Rails.application.routes.draw do
  get 'candidates/index'
  get 'candidates/show'
  get 'candidates/new'
  get 'candidates/create'
  get 'candidates/edit'
  get 'candidates/update'
  get 'candidates/destroy'
  resources :elections
  resources :offices
  resources :parties
  get 'up' => 'rails/health#show', as: :rails_health_check
end
