Rails.application.routes.draw do
  root 'other_users#index'
  resources :users, only: %i[new create]
  get 'login', to: 'user_sessions#new'
  get 'login', to: 'user_sessions#create'
end
