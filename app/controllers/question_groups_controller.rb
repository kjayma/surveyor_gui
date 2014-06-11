class QuestionGroupsController < ApplicationController

  def new
    @title = "Add Question"
    @question_group = QuestionGroup.new
    @question_group.questions.build
  end


  def edit
    @title = "Edit Question Group"
    @question_group = QuestionGroup.includes(:questions).find(params[:id])
  end

  def create
    @question_group = QuestionGroup.new(question_group_params)
    if @question_group.save
      render :inline => '<div id="cboxQuestionId">'+@question.id.to_s+'</div>', :layout=>'colorbox'
    else
      @title = "Add Question"
      redirect_to :action => 'new', :controller => 'questions', :layout=>'colorbox'
    end
  end

  def update
    @title = "Update Question"
    @question_group = QuestionGroup.includes(:questions).find(params[:id])
    if @question_group.update_attributes(question_group_params)
      render :blank, :layout=>'colorbox'
    else
      render :action => 'edit', :layout=>'colorbox'
    end
  end

  def render_group_inline_partial
    if params[:id].blank?
      @question_group = QuestionGroup.new
    else
      @question_group = QuestionGroup.find(params[:id])
    end
    if @question_group.questions.size == 0
      @question_group.questions.build
    end
    if params[:add_row]
      @question_group = QuestionGroup.new
      @question_group.questions.build
      render :partial => 'group_inline_field'
    else
      render :partial => 'group_inline_fields'
    end
  end
  private
  def question_group_params
    ::PermittedParams.new(params[:question_group]).question_group
  end
end
