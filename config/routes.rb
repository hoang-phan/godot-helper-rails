Rails.application.routes.draw do
  root "home#index"
  resources :files, only: %i(index)
  resources :roots, only: %i(update)
  resources :animations, only: %i(create)
  resources :components, only: %i(create)
end
