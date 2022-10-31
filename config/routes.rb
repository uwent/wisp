Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users, path: "wisp" do
    collection do
      get "report_setup"
    end
  end

  get "/wisp" => "welcome#index"
  get "/userguide" => "welcome#guide"
  get "fdw/irrig_only/:id" => "field_daily_weather#irrig_only"

  resources :welcome, only: [:index] do
    collection do
      get "about"
      get "guide"
      get "weather"
    end
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

  resources :crops do
    collection do
      post "post_data"
    end
  end

  resources :farms do
    collection do
      get "problems"
      post "post_data"
    end
  end

  resources :field_daily_weather do
    collection do
      post "post_data"
    end
  end

  resources :fields do
    collection do
      post "post_data"
    end
  end

  resources :irrigation_events

  resources :pivots do
    collection do
      post "post_data"
    end
  end

  resources :plants

  resources :users, only: [:index, :destroy]

  resources :weather_station_data do
    collection do
      post "post_data"
    end
  end

  # this is actually called 'Field Groups' on the sidebar
  resources :weather_stations

  root to: "welcome#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # redirect all wayward routes to home
  unless Rails.env.development?
    get "*path", to: redirect("/")
  end
end
