module SurveyorGui

  module SurveyformsControllerMethods

    def self.included(base)
      base.send :layout, 'surveyor_gui/surveyor_gui_default'
    end


    def index
      if params[:template]=='false'
        template=false
      elsif params[:template]=='true'
        template=true
      else
        template=false
      end
      @title = t('surveyor_gui.manage') + ' ' + (template ? t('surveyor_gui.templates') : t('surveyor_gui.survey_many'))
      @surveyforms = Surveyform.where('template = ?', template).search(params[:search]).order(:title).paginate(:page => params[:page])
    end


    def new
      @title = t('surveyor_gui.create_new') + (params[:template] == 'template' ? t('surveyor_gui.template') : t('surveyor_gui.survey'))
      @hide_survey_type = params[:hide_survey_type]
      template = params[:template] == 'template' ? true : false
      @surveyform = Surveyform.new(:template => template)
      @surveyform.survey_sections.build(:title => "#{t.('surveyor_gui.section')} 1", :display_order => 0, :modifiable => true) #.questions.build(:text=>'New question',:pick=>'none',:display_order=>0,:display_type=>'default', :modifiable=>modifiable).answers.build(:text=>'string', :response_class=>'string', :display_order=>1, :template=>true)  # FIXME I18n
      @question_no = 0
    end


    def edit
      @surveyform = Surveyform.where(:id => params[:id]).includes(:survey_sections).first
      @survey_locked=false
      #unfortunately, request.referrer does not seem to capture parameters. Need to add explicitly.
      #don't edit the format of a non template survey that has responses. could cause unpredictable results
      @surveyform.response_sets.where('test_data=?', true).map { |r| r.destroy }
      if !@surveyform.template && @surveyform.response_sets.count>0
        @survey_locked=true
        flash.now[:error] = I18n.t('surveyor_gui.surveyforms.edit.already_has_responses')
      end
      @title = t('surveyor_gui.edit') + ' ' + (@surveyform.template ? t('surveyor_gui.template') : t('surveyor_gui.survey')) # FIXME I18n
      @surveyform.survey_sections.build if @surveyform.survey_sections.blank?
      @question_no = 0
      @url = "update"
    end


    def create
      @surveyform = Surveyform.new(surveyforms_params.merge(user_id: @current_user.nil? ? @current_user : @current_user.id))
      if @surveyform.save
        flash[:notice] = t('surveyor_gui.surveyforms.create.success')
        @title = t('surveyor_gui.surveyforms.create.title')
        @question_no = 0
        redirect_to edit_surveyform_path(@surveyform.id)
      else
        flash[:error] = t('surveyor_gui.surveyforms.create.error')
        render :action => 'new'
      end
    end


    def update
      @title = t('surveyor_gui.surveyforms.update.title')
      @surveyform = Surveyform.includes(:survey_sections).find(params[:surveyform][:id])
      if @surveyform.update_attributes(surveyforms_params)
        flash[:notice] = t('surveyor_gui.surveyforms.update.success')
        redirect_to :action => :index
      else
        flash[:error] = t('surveyor_gui.surveyforms.update.error')
        @question_no = 0
        render :action => 'edit'
      end
    end


    def show
      @title = t('surveyor_gui.surveyforms.show.title')
      @survey_locked = true
      @surveyform = Surveyform.find(params[:id])
      @question_no = 0
    end


    def destroy
      @surveyform = Surveyform.find(params[:id])
      @surveyform.destroy
      if !@surveyform
        flash[:notice] = t('surveyor_gui.surveyforms.destroy.success')
        redirect_to surveyforms_url
      else
        if @surveyform.response_sets.count > 0
          flash[:error] = t('surveyor_gui.surveyforms.destroy.error.has_responses')
        else
          flash[:error] = t('surveyor_gui.surveyforms.destroy.error.could_not_delete')
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
      false
    end


    def paste_section
      @title= t('surveyor_gui.surveyforms.edit.title')
      @question_no = 0
      if session[:cut_section]
        _continue_paste_section
      else
        render :nothing => true
        false
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


    def _make_room(paste_at, _object_parent, object)
      statement = "object_parent."+object.class.to_s.underscore.pluralize
      collection = eval(statement)
      collection.where('display_order >= ?', paste_at).update_all('display_order=display_order+1')
    end


    def _save_pasted_object(object, surveyform, session_id)
      if object.save
        surveyform.reload
        session[session_id]=nil
        render :new, :layout => false
        true
      else
        render :nothing => true
        false
      end
    end


    def cut_question
      session[:cut_question]=params[:question_id]
      if q=Question.find(params[:question_id])
        @surveyform=q.survey_section.surveyform
        q.update_attribute(:survey_section_id, nil)
        q.question_group.questions.map { |q| q.update_attribute(:survey_section_id, nil) } if q.part_of_group?
        @question_no = 0
        render :new, :layout => false
        return true
      end
      render :nothing => true
      false
    end


    def paste_question
      @title= t('surveyor_gui.surveyforms.edit.title')
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
      question_id = params[:question_id]
      begin
        @question = Question.find(question_id)
        @question_no = 0
        render "_question_section", :layout => false
      rescue
        render inline: t('surveyor_gui.not_found')
      end
    end


    def clone_survey
      @title = t('surveyor_gui.surveyforms.clone.title')
      @surveyform = SurveyCloneFactory.new(params[:id]).clone
      if @surveyform.save
        flash[:notice] = t('surveyor_gui.surveyforms.clone.success')
        redirect_to edit_surveyform_path(@surveyform)
      else
        flash[:error] = t('surveyor_gui.surveyforms.clone.error')
        render :action => 'new'
      end
    end


    private

    def surveyforms_params
      PermittedParams.new(params[:surveyform]).survey
    end


  end
end
