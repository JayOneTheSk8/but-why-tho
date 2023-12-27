Rails.application.routes.draw do
  root "static_pages#home"
  post "sign_up", to: "users#create", format: "json"
end
