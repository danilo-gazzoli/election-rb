Rails.application.routes.draw do
  resources :elections
  get "up" => "rails/health#show", as: :rails_health_check
end
