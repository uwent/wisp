RailsApp::Application.routes.draw do
  get "omniauth_callbacks/google_oauth2"

  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}

  resources :plants

  match 'fdw/irrig_only/:id' => 'field_daily_weather#irrig_only'

  resources :field_daily_weather

  resources :weather_station_data, :collection => {:post_data => :post}

  resources :weather_stations

  # resources :crops
  
  # resources :fields

  resources :irrigation_events

  # resources :pivots

  # resources :farms

  get "sessions/new"

  get "sessions/create"

  get "sessions/destroy"
  
  match "/userguide" => "wisp#userguide"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"
  root :to => "wisp#index"
  
  resource :session
  match '/signin', :to => 'sessions#signin'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
end
