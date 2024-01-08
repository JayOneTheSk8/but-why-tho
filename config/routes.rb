Rails.application.routes.draw do
  root "static_pages#home"
  post "sign_up", to: "users#create", format: "json"
  get "users/:username", to: "users#show", format: "json"

  post "sign_in", to: "sessions#create", format: "json"
  get "sign_out", to: "sessions#destroy", format: "json"

  resources :email_confirmations, only: [:edit, :create], param: :confirmation_token
  resources :posts, format: "json"
  resources :comments, only: [:show, :create, :update, :destroy], format: "json"

  post "follows", to: "follows#create", format: "json"
  delete "follows", to: "follows#destroy", format: "json"

  post "comment_likes", to: "likes#create_comment_like", format: "json"
  delete "comment_likes", to: "likes#destroy_comment_like", format: "json"

  post "post_likes", to: "likes#create_post_like", format: "json"
  delete "post_likes", to: "likes#destroy_post_like", format: "json"

  get "users/:user_id/posts", to: "posts#user_posts", format: "json"
  get "users/:user_id/comments", to: "comments#user_comments", format: "json"
  get "users/:user_id/subscriptions", to: "follows#followed_users", format: "json"
  get "users/:user_id/followers", to: "follows#followers", format: "json"
  get "users/:user_id/likes", to: "likes#user_likes", format: "json"
end
