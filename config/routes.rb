Rails.application.routes.draw do
  get 'main/index'

  get 'main/get_rates', to: 'main#get_rates'
  post 'main/load_rates', to: 'main#load_rates'

  post 'notify/index', to: 'notify#index'
  post 'notify/create', to: 'notify#create'
  post 'notify/remove', to: 'notify#remove'
  
  get 'rate/index', to: 'rate#index'
  
  root 'main#index'

  require 'resque_web'
  mount ResqueWeb::Engine, at: "/resque_web"
end
