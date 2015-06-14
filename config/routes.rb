RailsApp::Application.routes.draw do
  get "omniauth_callbacks/google_oauth2"

  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}

  resources :plants

  match 'fdw/irrig_only/:id' => 'field_daily_weather#irrig_only'

  resources :field_daily_weather

  resources :weather_station_data, :collection => {:post_data => :post}

  resources :weather_stations

  resources :irrigation_events

  get "sessions/new"

  get "sessions/create"

  get "sessions/destroy"

  match "/userguide" => "wisp#userguide"

  root :to => "wisp#index"

  resource :session
  match '/signin', :to => 'sessions#signin'

  match ':controller(/:action(/:id(.:format)))'
end
