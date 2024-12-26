Rails.application.routes.draw do
  root "static_pages#home"

  get "static_pages/home"
  get "signup", to: "users#new"
  post "signup", to: "users#create"
  get "users/edit"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  resources :users, only: %i[new create]
  resources :account_activations, only: :edit
  resources :tasks, only: %i[new index edit update destroy create] do
    post :create_subtask, on: :collection
    resources :comments, only: %i[create destroy]
  end
end
