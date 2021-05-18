Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users, path: 'wisp'

  get '/userguide' => 'welcome#guide'
  get 'fdw/irrig_only/:id' => 'field_daily_weather#irrig_only'

  resources :welcome, only: [:index] do
    collection do
      get 'about'
      get 'guide'
      get 'weather'
    end
  end

  resources :wisp, only: [:index] do
    collection do
      get 'crop_setup_grid'
      post 'crop_setup_grid'
      get 'farm_status'
      get 'field_setup_grid'
      get 'field_status'
      get 'pivot_crop'
      get 'project_status'
      get 'projection_data'
      get 'report_setup'
      get 'summary_box'
      get 'weather'
    end
  end

  resources :farms, only: [:index] do
    collection do
      get 'problems'
      post 'post_data'
    end
  end

  resources :pivots, only: [:index] do
    collection do
      post 'post_data'
    end
  end

  resources :fields, only: [:index] do
    collection do
      post 'post_data'
    end
  end

  resources :crops, only: [:index] do
    collection do
      post 'post_data'
    end
  end

  resources :field_daily_weather, only: [:index] do
    collection do
      post 'post_data'
    end
  end

  resources :weather_station_data, only: [:index] do
    collection do
      post 'post_data'
    end
  end

  resources :irrigation_events
  resources :plants
  resources :weather_stations
  resources :users, only: [:index, :destroy]
  resources :awon, only: [:index]
  resources :weather, only: [:index]




  # TODO: Remove this eventually
  # match ':controller(/:action(/:id(.:format)))', via: [:get, :post]

  root to: 'welcome#index'

end
