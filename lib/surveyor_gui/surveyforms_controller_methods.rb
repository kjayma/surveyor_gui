module SurveyorGui

  module SurveyformsControllerMethods

    def self.included(base)
      base.send :layout, 'surveyor_gui/surveyor_gui_default'
    end


    def index
      # TODO I18n translation localization needed
      if params[:template]=='false'
        template=false
      elsif params[:template]=='true'
        template=true
      else
        template=false
      end
      @title = "Manage " + (template ? "Templates" : "Surveys")
      @surveyforms = Surveyform.where('template = ?', template).search(params[:search]).order(:title).paginate(:page => params[:page])
    end


    def new
      # TODO I18n translation localization needed
      @title = "Create New "+ (params[:template] == 'template' ? 'Template' : 'Survey')
      @hide_survey_type = params[:hide_survey_type]
      template = params[:template] == 'template' ? true : false
      @surveyform = Surveyform.new(:template => template)
      @surveyform.survey_sections.build(:title => 'Section 1', :display_order => 0, :modifiable => true) #.questions.build(:text=>'New question',:pick=>'none',:display_order=>0,:display_type=>'default', :modifiable=>modifiable).answers.build(:text=>'string', :response_class=>'string', :display_order=>1, :template=>true)
      @question_no = 0
    end


    def edit
      # TODO I18n translation localization needed
      @surveyform = Surveyform.where(:id => params[:id]).includes(:survey_sections).first
      @survey_locked=false
      #unfortunately, request.referrer does not seem to capture parameters. Need to add explicitly.
      #don't edit the format of a non template survey that has responses. could cause unpredictable results
      @surveyform.response_sets.where('test_data=?', true).map {|r| r.destroy}
      if !@surveyform.template && @surveyform.response_sets.count>0
        @survey_locked=true
        flash.now[:error] = "Reponses have already been collected for this survey, therefore modifications are not permitted."
      end
      @title = "Edit "+ (@surveyform.template ? 'Template' : 'Survey')
      @surveyform.survey_sections.build if @surveyform.survey_sections.blank?
      @question_no = 0
      @url = "update"
    end


    def create
      # TODO I18n translation localization needed
      @surveyform = Surveyform.new(surveyforms_params.merge(user_id: @current_user.nil? ? @current_user : @current_user.id))
      if @surveyform.save
        flash[:notice] = "Successfully created survey."
        @title = "Edit Survey"
        @question_no = 0
        redirect_to edit_surveyform_path(@surveyform.id)
      else
        render :action => 'new'
      end
    end


    def update
      # TODO I18n translation localization needed
      @title = "Update Survey"
      @surveyform = Surveyform.includes(:survey_sections).find(params[:surveyform][:id])
      if @surveyform.update_attributes(surveyforms_params)
        flash[:notice] = "Successfully updated surveyform."
        redirect_to :action => :index
      else
        flash[:error] = "Changes not saved."
        @question_no = 0
        render :action => 'edit'
      end
    end


    def show
      # TODO I18n translation localization needed
      @title = "Show Survey"
      @survey_locked = true
      @surveyform = Surveyform.find(params[:id])
      @question_no = 0
    end


    def destroy
      # TODO I18n translation localization needed
      @surveyform = Surveyform.find(params[:id])
      @surveyform.destroy
      if !@surveyform
        flash[:notice] = "Successfully destroyed survey."
        redirect_to surveyforms_url
      else
        if @surveyform.response_sets.count > 0
          flash[:error] = 'This survey has responses and can not be deleted'
        else
          flash[:error] = 'Survey could not be deleted.'
        end
        redirect_to surveyforms_url
      end
    end


    def replace_form
      @surveyform = SurveySection.find(params[:survey_section_id]).surveyform
      @question_no = 0
      render :new, :layout => false
    end


    def insert_survey_section
      survey_id = params[:id]
      @survey_section = Survey.find(survey_id).survey_sections.reorder('survey_sections.id').last
      if @survey_section
        @question_no = 0
        render "_survey_section_fields", :layout => false
      else
        render :nothing => true
      end
    end


    def replace_survey_section
      survey_section_id = params[:survey_section_id]
      @survey_section = SurveySection.find(survey_section_id)
      @question_no = 0
      render "_survey_section_fields", :layout => false
    end


    def insert_new_question
      question_id = params[:question_id]
      @question = Question.find(question_id)
      @question_no = 0
      @surveyform = @question.survey_section.surveyform
      render :new, :layout => false
    end


    def cut_section
      session[:cut_section]=params[:survey_section_id]
      if ss=SurveySection.find(params[:survey_section_id])
        @surveyform=ss.surveyform
        ss.update_attribute(:survey_id, nil)
        @question_no = 0
        render :new, :layout => false
        return true
      end
      render :nothing => true
      return false
    end


    def paste_section
      # TODO I18n translation localization needed
      @title="Edit Survey"
      @question_no = 0
      if session[:cut_section]
        _continue_paste_section
      else
        render :nothing => true
      end
    end


    def _continue_paste_section
      survey_section = SurveySection.find(session[:cut_section])
      place_at_section = SurveySection.find(params[:survey_section_id])
      survey_section.survey_id = place_at_section.survey_id
      survey_section.display_order = _paste_to(params[:position], place_at_section.survey, place_at_section)
      @surveyform = place_at_section.surveyform
      _save_pasted_object(survey_section, @surveyform, :cut_section)
    end


    def _paste_to(position, object_parent, object)
      paste_position = object.display_order + _display_order_offset(position)
      _make_room(paste_position, object_parent, object)
      paste_position
    end


    def _display_order_offset(position)
      position == "over" ? 0 : 1
    end


    def _make_room(paste_at, object_parent, object)
      statement = "object_parent."+object.class.to_s.underscore.pluralize
      collection = eval(statement)
      collection.where('display_order >= ?', paste_at).update_all('display_order=display_order+1')
    end


    def _save_pasted_object(object, surveyform, session_id)
      if object.save
        surveyform.reload
        session[session_id]=nil
        render :new, :layout => false
      else
        render :nothing => true
        return false
      end
    end


    def cut_question
      session[:cut_question]=params[:question_id]
      if q=Question.find(params[:question_id])
        @surveyform=q.survey_section.surveyform
        q.update_attribute(:survey_section_id, nil)
        q.question_group.questions.map {|q| q.update_attribute(:survey_section_id, nil)} if q.part_of_group?
        @question_no = 0
        render :new, :layout => false
        return true
      end
      render :nothing => true
      return false
    end


    def paste_question
      # TODO I18n translation localization needed
      @title="Edit Survey"
      if session[:cut_question]
        @question = Question.find(session[:cut_question])
        @question_no = 0
        if params[:question_id]
          place_under_question = Question.find(params[:question_id])
          survey_section = place_under_question.survey_section
          survey_section_id = survey_section.id
          survey_section.questions.where('display_order>?', place_under_question.display_order).update_all('display_order=display_order+1')
          @question.display_order = place_under_question.display_order+1
          @surveyform = survey_section.surveyform
        else
          survey_section_id = params[:survey_section_id]
          @question.display_order = 0
          SurveySection.find(survey_section_id).questions.update_all('display_order = display_order+1')
          @surveyform = SurveySection.find(survey_section_id).surveyform
        end
        @question.survey_section_id = survey_section_id

        if @question.save
          @surveyform.reload
          session[:cut_question]=nil
          render :new, :layout => false
        else
          render :nothing => true
          return false
        end
      end
    end


    def replace_question
      # TODO I18n translation localization needed
      question_id = params[:question_id]
      begin
        @question = Question.find(question_id)
        @question_no = 0
        render "_question_section", :layout => false
      rescue
        render inline: "not found"
      end
    end


    def clone_survey
      # TODO I18n translation localization needed
      @title = "Clone Survey"
      @surveyform = SurveyCloneFactory.new(params[:id]).clone
      if @surveyform.save
        flash[:notice] = "Successfully created survey, questionnaire, or form."
        redirect_to edit_surveyform_path(@surveyform)
      else
        flash[:error] = "Could not clone the survey, questionnaire, or form."
        render :action => 'new'
      end
    end



    private

    def surveyforms_params
      PermittedParams.new(params[:surveyform]).survey
    end


  end
end
