Rails.application.routes.draw do
  get '/orders/available', to: 'orders#available_orders'
  resources :orders
  get '/orders/user/:user_id/active', to: 'orders#user_active_orders'

  resources :subcategories
  resources :categories
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
