class QuestionsController < ApplicationController
  layout 'surveyor_gui_blank'

  def new
    @title = "Add Question"
    survey_section = SurveySection.find(params[:survey_section_id])
    survey = Survey.find(survey_section.survey_id)
    @question_group = QuestionGroup.new
    if params[:prev_question_id]
      prev_question_display_order = _get_prev_display_order(params[:prev_question_id])
      @question = Question.new(:survey_section_id => params[:survey_section_id],
                               :text => params[:text],
                               :display_type => "default",
                               :display_order => prev_question_display_order)
    else
      @question = Question.new(:survey_section_id => params[:survey_section_id],
                               :text => params[:text],
                               :display_type => "default",
                               :display_order => params[:display_order] || 0)
    end
    @question.question_type_id = params[:question_type_id] if !params[:question_type_id].blank?
    @question.answers.build(:text => '', :response_class=>"string")
  end

  def edit
    @title = "Edit Question"
    @question = Question.includes(:answers).find(params[:id])
    @question.question_type_id = params[:question_type_id] if !params[:question_type_id].blank?
  end

  def adjusted_text
    if @question.part_of_group?
      @question.question_group.text
    else
      @question.text
    end
  end

  helper_method :adjusted_text

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
      render :inline => '<div id="cboxQuestionId">'+@question.id.to_s+'</div>', :layout => 'surveyor_gui_blank'
    else
      @title = "Add Question"
      render :action => 'new', :layout => 'surveyor_gui_blank'
    end
  end

  def update
    @title = "Update Question"
    @question = Question.includes(:answers).find(params[:id])
    if @question.update_attributes(question_params)
      @question.answers.each_with_index {|a, index| a.destroy if index > 0} if @question.pick == 'none'
      #load any page - if it has no flash errors, the colorbox that contains it will be closed immediately after the page loads
      render :blank, :layout => 'surveyor_gui_blank'
    else
      render :action => 'edit', :layout => 'surveyor_gui_blank'
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
    if question.part_of_group?
      question.question_group.questions.each{|q| q.destroy}
      render :text=>''
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
      @questions.answers.build(text: "", response_class: "answer")
    else
      if !@questions.answers.first.original_choice.blank?
        @questions.answers.first.update_attribute(:text,@questions.answers.first.original_choice)
      end
    end
    if @questions.question_group
      @question_group=@questions.question_group
    else
      @question_group=QuestionGroup.new
      @question_group.columns.build
    end
    column_count = @question_group.columns.size
    requested_columns = params[:index] == "NaN" ? column_count : params[:index].to_i
    if requested_columns >= column_count
      requested_columns = requested_columns - column_count
      (requested_columns).times.each {@question_group.columns.build}
    else
      @question_group.trim_columns (column_count-requested_columns)
    end
    @questions.dropdown_column_count = requested_columns.to_i+1
    if params[:question_type_id] == "grid_dropdown"
      render :partial => 'grid_dropdown_fields'
    else
      render :partial => 'grid_fields'
    end
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

  def _get_prev_display_order(prev_question)
    prev_question = Question.find(prev_question)
    if prev_question.part_of_group?
      prev_question.question_group.questions.last.display_order + 1
    else
      prev_question.display_order + 1
    end
  end
end
