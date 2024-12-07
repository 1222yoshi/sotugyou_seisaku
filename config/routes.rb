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
      get 'share'
    end
    collection do
      get 'sort'
      post 'select'
      post 'swap'
    end
  end
  resources :other_users, only: %i[index show] do
    collection do
      get 'quiz_result'
    end
  end
  resources :likes, only: %i[create] do
    collection do
      get 'like_user'
      get 'liked_user'
      get 'match_user'
    end
  end
  resources :chatrooms, only: %i[index show create] do
    post :post_message, on: :member
  end
  resources :quizzes, only: %i[index show create] do
    collection do
      get 'music_theory'
      get 'rhythm'
    end
    member do
      get 'result'
    end
  end
  resources :password_resets, only: %i[new create edit update]
  resources :email_resets, only: %i[new create update] do
    member do
      get 'pass'
    end
  end
  mount ActionCable.server => '/cable'
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
end
