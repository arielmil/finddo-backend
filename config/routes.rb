Rails.application.routes.draw do
  # Orders
  get '/orders/available', to: 'orders#available_orders'
  put '/orders/associate/:id', to: 'orders#associate_professional'
  get '/orders/user/:user_id/active', to: 'orders#user_active_orders'
  get '/orders', to: 'orders#index'
  post '/orders', to: 'orders#create'
  get '/orders/:id', to: 'orders#show'
  put '/orders/:id', to: 'orders#update'
  delete '/orders/:id', to: 'orders#destroy'

  resources :categories
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
