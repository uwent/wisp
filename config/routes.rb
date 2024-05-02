Rails.application.routes.draw do
  root to: "home#index"

  get "wisp" => redirect("")
  get "home" => redirect("")

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users, path: "wisp" do
    collection do
      get "report_setup"
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

  resources :farms, only: :index do
    collection do
      get "problems"
      post "post_data"
    end
  end

  resources :pivots, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :fields, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :field_daily_weather, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :crops, only: :index do
    collection do
      post "post_data"
    end
  end

  resources :users, only: [:index, :show, :destroy]

  # this is actually called 'Field Groups' on the sidebar
  resources :weather_stations

  resources :weather_station_data do
    collection do
      post "post_data"
    end
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # redirect all wayward routes to home
  get "*path", to: redirect("/") unless Rails.env.development?
end
