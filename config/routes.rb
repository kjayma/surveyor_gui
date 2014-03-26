Rails.application.routes.draw do

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
  resources :surveyforms do
    member do
      get 'replace_form'
      get 'insert_survey_section'
      get 'replace_survey_section'
      get 'insert_new_question'
      get 'replace_question'
      get 'clone'
      put 'create_cloned'
      get 'set_default'
      get 'cut_question'
      get 'paste_question'
    end
  end

  resources :survey_sections do
    post :sort, :on => :collection
  end

  match '/questions/sort',   :to => 'questions#sort'

  resources :questions do
    member do
      get 'cut'
    end
  end

  match '/question/render_picks_partial', :to => 'questions#render_picks_partial'
  match '/question/render_no_picks_partial', :to => 'questions#render_no_picks_partial'

  match '/answers/sort',   :to => 'answers#sort'

  resources :dependencys do
    collection do
      get 'get_answers'
      get 'get_question_type'
    end
  end

  resources :surveyresponses,
    :only=>['preview_results',
            'preview_survey',
            'preview_report',
            'test',
            'prepare_value_analysis_report',
            'prepare_recommendation_report',
            'show_recommendation_pdf',
            'show_results' ] do
      member do
        get 'preview_results'
        get 'preview_survey'
        get 'preview_report'
        get 'test'
        get 'prepare_recommendation_report'
        get 'show_recommendation_pdf'
        get 'show_results'
      end
    end

end
