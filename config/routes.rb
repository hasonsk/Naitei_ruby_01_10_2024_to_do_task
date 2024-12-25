Rails.application.routes.draw do
  root "static_pages#home"

  get "static_pages/home"
  get "users/new"
  get "users/edit"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  resources :tasks, only: [:new, :index, :edit, :update, :destroy, :create] do
    post :create_subtask, on: :collection
    resources :comments, only: [:create, :destroy]
  end
end
