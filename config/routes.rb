Rails.application.routes.draw do
  root "static_pages#home"

  get "static_pages/home"
  get "users/new"
  get "users/edit"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  resources :tasks, only: %i[new index edit destroy create] do
    resources :subtasks, only: %i[create]
    resources :comments, only: %i[create destroy]
  end
end
