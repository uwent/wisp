RailsApp::Application.routes.draw do
  devise_for :users

  match '/userguide' => 'wisp#userguide'
  match 'fdw/irrig_only/:id' => 'field_daily_weather#irrig_only'

  resources :field_daily_weather
  resources :irrigation_events
  resources :plants
  resources :weather_station_data, collection: { post_data: :post }
  resources :weather_stations

  root to: "wisp#index"
end
