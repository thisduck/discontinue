Rails.application.routes.draw do
  devise_for :users
  post 'session' => 'session#create'
  get 'users/current' => 'session#current'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount_ember_app :frontend, to: "/"
end
