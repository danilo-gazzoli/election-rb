Rails.application.routes.draw do
  get 'elections/index'
  get 'elections/show'
  get 'elections/new'
  get 'elections/create'
  get 'elections/edit'
  get 'elections/update'
  get 'elections/destroy'
  get "up" => "rails/health#show", as: :rails_health_check
end
