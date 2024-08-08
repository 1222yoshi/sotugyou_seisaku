Rails.application.routes.draw do
  root 'other_users#index'
  resources :users, only: %i[new create]
end
