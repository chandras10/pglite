Pglite::Application.routes.draw do

  resources :users
  resources :sessions, only: [:new, :create, :destroy]
  resources :deviceinfos do 
    collection do 
      put 'authorize'
    end
  end

  resources :autocomplete_tags, only: [] do
     get :usernames, :on => :collection
     get :groupnames, :on => :collection
     get :countrycodes, :on => :collection
  end

  resources :i7alerts

  root to: 'reports#dash_inventory'

  match '/signin', to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete
  
  match '/dash_inventory', to: 'reports#dash_inventory'
  match '/dash_inventory_bandwidth_stats', to: 'reports#dash_inventory_bandwidth_stats'
  match '/tbl_inventory', to: 'deviceinfos#index'

  match '/dash_bw', to: 'reports#dash_bw'
  match '/dash_bw_server', to: 'reports#dash_bw_server'
  match '/dash_bw_pivottable', to: 'reports#dash_bw_pivottable'
  match '/dash_bw_world', to: 'reports#dash_bw_world'
  match '/dash_bw_country', to: 'reports#dash_bw_country'
  match '/dash_bw_country_details', to: 'reports#dash_bw_country_details'

  match '/tbl_snort', to: 'reports#tbl_snort'
  match '/dash_snort', to: 'reports#dash_snort'
  match '/tbl_vulnerability', to: 'reports#tbl_vulnerability'

  match '/device_details', to: 'reports#device_details'

  match '/policy', to: 'configuration#edit_policy', :via => :get
  match '/policy', to: 'configuration#save_policy', :via => :post

  match '/settings', to: 'settings#settings_menu', :via => :get
  match '/settings', to: 'settings#save_settings', :via => :post

  # Batch Reports
  match '/dvi_report', to:  'batch_reports#dvi_report'

  match '/alerts', to: 'i7alerts#index'
  
  match '/500', to: 'errors#internal_error'
  match '/404', to: 'errors#internal_error'


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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
