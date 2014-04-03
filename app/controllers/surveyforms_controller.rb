class SurveyformsController < ApplicationController
  def index
    if params[:template]=='false'
      template=false
    elsif params[:tempate]=='true'
      template=true
		else
			template=false
    end
    @title = "Modify " + (template ? "Templates" : "Surveys")
	 	@surveyforms = Surveyform.where('template = ?',template).search(params[:search]).order(:title).paginate(:page => params[:page])
  end

  def new
    @title = "Create New "+ (params[:template] == 'template'? 'Template' : 'Survey')
    @hide_survey_type = params[:hide_survey_type]
    template = params[:template] == 'template'? true : false
    @surveyform = Surveyform.new(:template=>template)
    @surveyform.survey_sections.build(:title=>'Section 1', :display_order=>0, :modifiable=>true)#.questions.build(:text=>'New question',:pick=>'none',:display_order=>0,:display_type=>'default', :modifiable=>modifiable).answers.build(:text=>'string', :response_class=>'string', :display_order=>1, :template=>true)
    @question_no = 0
  end

  def edit
    @surveyform = Surveyform.where(:id=>params[:id]).includes(:survey_sections).first
    @survey_locked=false
    #unfortunately, request.referrer does not seem to capture parameters. Need to add explicitly.
    #don't edit the format of a non template survey that has responses. could cause unpredictable results
    @surveyform.response_sets.where('test_data=?',true).map{|r| r.destroy}
    if !@surveyform.template && @surveyform.response_sets.count>0
      @survey_locked=true
      flash.now[:error] = "Reponses have already been collected for this survey, therefore any modifications you make will not be saved."
    end
    @title = "Edit "+ (@surveyform.template ? 'Template' : 'Survey')
    @surveyform.survey_sections.build if @surveyform.survey_sections.blank?
    @question_no = 0
    @url = "update"
  end

  def create
    @surveyform = Surveyform.new(params[:surveyform])
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
    @title = "Update Survey"
    @surveyform = Surveyform.find(params[:surveyform][:id], :include =>:survey_sections)
    if @surveyform.update_attributes(params[:surveyform])
      flash[:notice] = "Successfully updated surveyform."
      redirect_to :action=>:index
    else
      flash[:error] = "Changes not saved."
      @question_no = 0
      render :action => 'edit'
    end
  end

  def show
    @title = "Edit Survey"
    @surveyform = Surveyform.find(params[:id], :include =>:survey_sections)
    @surveyform = Surveyform.where(:id=>params[:id]).includes(:survey_sections).first
    @question_no=0
    render :edit
  end

  def destroy
    @surveyform = Surveyform.find(params[:id])
    @surveyform.destroy
    if !@surveyform
      flash[:notice] = "Successfully destroyed survey."
      redirect_to surveyforms_url
    else
      flash.now[:error] = 'Survey could not be deleted.'
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
    @survey_section = Survey.find(survey_id, :include=> :survey_sections, :order => 'survey_sections.id').survey_sections.last
    if @survey_section
      @question_no = 0
      render "_survey_section_fields" , :layout=> false
    else
      render :nothing=> true
    end
  end

  def replace_survey_section
    survey_section_id = params[:survey_section_id]
    @survey_section = SurveySection.find(survey_section_id)
    @question_no = 0
    render "_survey_section_fields" , :layout=> false
  end

  def insert_new_question
    question_id = params[:question_id]
    @question = Question.find(question_id)
    @question_no = 0
    @surveyform = @question.survey_section.surveyform
    render :new, :layout=>false
  end

  def cut_section
    session[:cut_section]=params[:survey_section_id]
    if ss=SurveySection.find(params[:survey_section_id])
      @surveyform=ss.surveyform
      ss.update_attribute(:survey_id,nil)
      @question_no = 0
      render :new, :layout=>false
      return true
    end
    render :nothing=>true
    return false
  end

  def paste_section
    @title="Edit Survey"
    if session[:cut_section]
      survey_section = SurveySection.find(session[:cut_section])
      @question_no = 0
      if params[:survey_section_id]
        place_under_section = SurveySection.find(params[:survey_section_id])
        survey = place_under_section.survey
        survey_id = survey.id
        survey.survey_sections.where('display_order>?',place_under_section.display_order).update_all('display_order=display_order+1')
        survey_section.display_order = place_under_section.display_order+1
        @surveyform = survey
      else
        survey_id = params[:survey_id]
        survey_section.display_order = 0
        Survey.find(survey_id).survey_sections.update_all('display_order = display_order+1')
        @surveyform = Surveyform.find(survey_id)
      end
      survey_section.survey_id = survey_id

      if survey_section.save
        @surveyform.reload
        session[:cut_section]=nil
        render :new, :layout=>false
      else
        render :nothing=>true
        return false
      end
    else
      render :nothing=>true
    end
  end

  def cut_question
    session[:cut_question]=params[:question_id]
    if q=Question.find(params[:question_id])
      @surveyform=q.survey_section.surveyform
      q.update_attribute(:survey_section_id,nil)
      @question_no = 0
      render :new, :layout=>false
      return true
    end
    render :nothing=>true
    return false
  end

  def paste_question
    @title="Edit Survey"
    if session[:cut_question]
      @question = Question.find(session[:cut_question])
      @question_no = 0
      if params[:question_id]
        place_under_question = Question.find(params[:question_id])
        survey_section = place_under_question.survey_section
        survey_section_id = survey_section.id
        survey_section.questions.where('display_order>?',place_under_question.display_order).update_all('display_order=display_order+1')
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
        render :new, :layout=>false
      else
        render :nothing=>true
        return false
      end
    end
  end

  def replace_question
    question_id = params[:question_id]
    @question = Question.find(question_id)
    @question_no = 0
    render "_question_section" , :layout=> false
  end


end
