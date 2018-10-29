Rails.application.routes.draw do
  post 'session' => 'session#create'

  get 'github/repositories'
  get 'github/pull_requests'
  post 'github/webhook'

  get 'api/users/current' => 'session#current'
  namespace :api do
    jsonapi_resources :repositories
    jsonapi_resources :build_requests do
      jsonapi_relationships
      collection do 
        put :build_from_pull
      end
      member do
        put :trigger_event
      end
    end
    jsonapi_resources :builds do
      jsonapi_relationships
      member do
        put :trigger_event
      end
    end
    jsonapi_resources :streams
    jsonapi_resources :boxes
    jsonapi_resources :test_results
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount_ember_app :frontend, to: "/"
end
