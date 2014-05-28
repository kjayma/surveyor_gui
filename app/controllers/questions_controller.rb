class QuestionsController < ApplicationController

  def new
    @title = "Add Question"
    survey_section = SurveySection.find(params[:survey_section_id])
    survey = Survey.find(survey_section.survey_id)
    if params[:prev_question_id]
      prev_question = Question.find(params[:prev_question_id])
      @question = Question.new(:survey_section_id => params[:survey_section_id],
                               :display_order => prev_question.display_order + 1)
    else
      @question = Question.new(:survey_section_id => params[:survey_section_id],
                               :display_order => 0)
    end
    @question.answers.build(:text => '')
  end

  def edit
    @title = "Edit Question"
    @question = Question.includes(:answers).find(params[:id])
  end

  def create
    Question.where(:survey_section_id => params[:question][:survey_section_id])
            .where("display_order >= ?", params[:question][:display_order])
            .update_all("display_order = display_order+1")
    if !params[:question][:answers_attributes].blank? && !params[:question][:answers_attributes]['0'].blank?
      params[:question][:answers_attributes]['0'][:original_choice] = params[:question][:answers_attributes]['0'][:text]
    end

    @question = Question.new(question_params)
    if @question.save
      @question.answers.each_with_index {|a, index| a.destroy if index > 0} if @question.pick == 'none'
      #load any page - if it has no flash errors, the colorbox that contains it will be closed immediately after the page loads
      render :inline => '<div id="cboxQuestionId">'+@question.id.to_s+'</div>', :layout=>'colorbox'
    else
      @title = "Add Question"
      render :action => 'new', :layout=>'colorbox'
    end
  end

  def update
    @title = "Update Question"
    @question = Question.includes(:answers).find(params[:id])
    if @question.update_attributes(question_params)
      @question.answers.each_with_index {|a, index| a.destroy if index > 0} if @question.pick == 'none'
      #load any page - if it has no flash errors, the colorbox that contains it will be closed immediately after the page loads
      render :blank, :layout=>'colorbox'
    else
      render :action => 'edit', :layout=>'colorbox'
    end
  end

  def destroy
    question = Question.find(params[:id])
    if !question.survey_section.survey.template && question.survey_section.survey.response_sets.count > 0
      flash[:error]="Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead."
      return false
    end
    if !question.dependency_conditions.blank?
      render :text=>"The following questions have logic that depend on this question: \n\n"+question.dependency_conditions.map{|d| " - "+d.dependency.question.text}.join('\n')+"\n\nPlease delete logic before deleting this question.".html_safe
      return
    end
    question.destroy
    render :text=>''
  end

  def sort
    survey = Surveyform.find(params[:survey_id])
    survey.sort_as_per_array(params)
    render :nothing => true
  end

  def cut_question
    session[:cut_question]=params[:id]
    if q=Question.find(params[:id])
      q.update_attribute(:survey_section_id,nil)
    end
    redirect_to :back
  end

  def render_answer_fields_partial
    if params[:id].blank?
      @questions = Question.new
    else
      @questions = Question.find(params[:id])
    end
    if @questions.answers.empty?
      @questions.answers.build(:text=>'')
    else
      if !@questions.answers.first.original_choice.blank?
        @questions.answers.first.update_attribute(:text,@questions.answers.first.original_choice)
      end
      if params[:add_row]
        display_order = @questions.answers.maximum(:display_order)
        display_order = display_order ? display_order + 1 : 0
        @questions = Question.new
        @questions.answers.build(:text=>'', :display_order=>display_order)
      end
    end
    render :partial => 'answer_fields'
  end
  
  def render_grid_partial
    if params[:id].blank?
      @questions = Question.new
    else
      @questions = Question.find(params[:id])
    end
    if @questions.answers.empty?
      @questions.answers.build(:text=>'')
    else
      if !@questions.answers.first.original_choice.blank?
        @questions.answers.first.update_attribute(:text,@questions.answers.first.original_choice)
      end
    end
    render :partial => 'grid_fields'
  end

  def render_no_picks_partial
    if params[:id].blank?
      @questions = Question.new
    else
      @questions = Question.find(params[:id])
    end
    if @questions.answers.empty?
      @questions.answers.build(:text=>'')
    end
    render :partial => 'no_picks'
  end

  private
  def question_params
    ::PermittedParams.new(params[:question]).question
  end

end
