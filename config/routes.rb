Rails.application.routes.draw do
  post 'session' => 'session#create'

  get 'github/repositories' => 'github#repositories'

  get 'api/users/current' => 'session#current'
  namespace :api do
    jsonapi_resources :repositories
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount_ember_app :frontend, to: "/"
end
