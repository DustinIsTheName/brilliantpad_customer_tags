Rails.application.routes.draw do

  post '/save-customer' => 'customer#save'
  get '/get-customer' => 'customer#get'
  post '/get-order' => 'customer#get_order'
  post '/earn-points' => 'customer#earn_points'
  post '/earn-points-typeform' => 'customer#earn_points_typeform'
  post '/save-order' => 'customer#save_order'
  post '/pre-order' => 'pre_order#tag_order'
  post '/get-refresh-token' => 'customer#refresh_token'


  get '/get-subscription' => 'subscription#current'
  post '/upgrade-subscription' => 'subscription#upgrade'
  get '/test' => 'subscription#test'

  controller :recharge do
    get '/recharge-customer' => :get_customer
    post '/recharge-update-customer' => :update_customer

    get '/recharge-address' => :get_address
    post '/recharge-update-address' => :update_address

    get '/recharge-customer-subscriptions' => :get_subscriptions
    post '/recharge-subscription-update' => :update_subscription
    post '/recharge-subscription-delay' => :delay_subscription
    post '/recharge-subscription-cancel' => :cancel_subscription

    get '/recharge-orders' => :get_orders

    get '/recharge-payment-source' => :get_payment_source
    post '/recharge-update-billing' => :update_billing

    post '/recharge-add-discount' => :add_discount
    post '/recharge-remove-discount' => :remove_discount

    get '/recharge-charge' => :get_charges
    post '/recharge-skip-charge' => :skip_charge
    post '/recharge-unskip-charge' => :unskip_charge

  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
