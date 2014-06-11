Rails.application.routes.draw do

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
      get 'cut_section'
      get 'paste_section'
      get 'cut_question'
      get 'paste_question'
    end
  end

  resources :survey_sections do
    post :sort, :on => :collection
  end

  match '/questions/sort',   :to => 'questions#sort', :via => :post

  resources :questions do
    member do
      get 'cut'
    end
  end

  resources :question_groups do
  end

  get '/question/render_answer_fields_partial', :to => 'questions#render_answer_fields_partial'
  get '/question/render_grid_partial', :to => 'questions#render_grid_partial'
  get '/question_group/render_group_inline_partial', :to => 'question_groups#render_group_inline_partial'
  get '/question/render_no_picks_partial', :to => 'questions#render_no_picks_partial'

  resources :dependencys do
    collection do
      get 'get_answers'
      get 'get_question_type'
      get 'get_columns'
    end
  end
  get '/dependency/render_dependency_conditions_partial', :to => 'dependencys#render_dependency_conditions_partial'

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
