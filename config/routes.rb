Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users, path: "wisp" do
    collection do
      get "report_setup"
    end
  end

  get "/wisp" => "home#index"
  get "/userguide" => "home#guide"
  get "fdw/irrig_only/:id" => "field_daily_weather#irrig_only"

  resources :home, only: [:index] do
  end

  resources :wisp, only: [] do
    collection do
      get "project_status"
      get "pivot_crop"
      post "pivot_crop"
      get "field_setup_grid"
      post "field_setup_grid"
      get "crop_setup_grid"
      post "crop_setup_grid"
      get "weather"
      post "weather"
      get "lookup"
      get "field_status"
      post "field_status"
      get "projection_data"
      get "farm_status"
      get "report_setup"
      get "summary_box"
      post "set_farm"
      post "set_pivot"
      post "set_field"
    end
  end

  resources :crops, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :farms, only: :index do
    collection do
      get "problems"
      post "post_data"
    end
  end

  resources :field_daily_weather, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :fields, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :irrigation_events

  resources :pivots, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :plants

  resources :users, only: [:index, :destroy]

  # this is actually called 'Field Groups' on the sidebar
  resources :weather_stations

  resources :weather_station_data do
    collection do
      post "post_data"
    end
  end



  root to: "home#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # redirect all wayward routes to home
  unless Rails.env.development?
    get "*path", to: redirect("/")
  end
end
