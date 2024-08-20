Rails.application.routes.draw do
  root 'other_users#index'
  resources :users, only: %i[new create]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
  resource :profile, only: %i[show edit update]
  resources :albums, only: %i[index show destroy] do
    member do
      get 'choose'
      post 'share'
    end
  end
  resources :other_users, only: %i[index show]
end
