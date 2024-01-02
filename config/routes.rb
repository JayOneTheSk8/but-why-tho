Rails.application.routes.draw do
  root "static_pages#home"
  post "sign_up", to: "users#create", format: "json"

  post "sign_in", to: "sessions#create", format: "json"
  get "sign_out", to: "sessions#destroy", format: "json"

  resources :email_confirmations, only: [:edit, :create], param: :confirmation_token
  resources :posts, format: "json"

  get "users/:user_id/posts", to: "posts#user_posts", format: "json"
end
