Rails.application.routes.draw do
  post 'session' => 'session#create'

  get 'github/repositories'
  post 'github/webhook'

  get 'api/users/current' => 'session#current'
  namespace :api do
    jsonapi_resources :repositories
    jsonapi_resources :build_requests do
      member do
        put :trigger_event
      end
    end
    jsonapi_resources :builds do
      member do
        put :trigger_event
      end
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount_ember_app :frontend, to: "/"
end
