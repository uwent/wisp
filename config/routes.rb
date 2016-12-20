RailsApp::Application.routes.draw do
  devise_for :users

  get '/userguide' => 'welcome#guide'
  get 'fdw/irrig_only/:id' => 'field_daily_weather#irrig_only'

  resources :field_daily_weather
  resources :irrigation_events
  resources :plants
  resources :weather_station_data, collection: { post_data: :post }
  resources :weather_stations
  resources :users, only: [:index, :destroy]

  resources :welcome, only: [:index] do
    collection do
      get :about
      get :weather
      get :guide
    end
  end

  root to: 'welcome#index'

  # TODO: Remove this eventually
  match ':controller(/:action(/:id(.:format)))', via: [:get, :post]
end
