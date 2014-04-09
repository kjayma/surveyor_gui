class DependencysController < ApplicationController

  def new
    prep_variables
    @title = "Add Logic for "+@this_question
    @question.build_dependency(:rule=>'A')
  end

  def edit
    prep_variables
    @title = "Edit Logic for Question "+@this_question
  end

  def create
    @question = Question.new(params[:question])
    if @question.save
      redirect_to :back
    else
      render :action => 'new', :layout=>'colorbox'
    end
  end

  def update
    @title = "Update Question"
    @question = Question.includes(:answers).find(params[:id])
    if @question.update_attributes(params[:question])
      @question.dependency.destroy if @question.dependency.dependency_conditions.blank?
      render :blank, :layout=>'colorbox'
    else
      prep_variables
      render :action => 'edit', :layout=>'colorbox'
    end
  end

  def destroy
    question = Question.find(params[:id])
    question.dependency.destroy
    render :nothing=>true
  end

  def render_dependency_conditions_partial
    prep_variables
    if @question.dependency.nil?
      @question.build_dependency(:rule=>'A').dependency_conditions.build()
    end
    if @question.dependency.dependency_conditions.empty?
      @question.dependency.dependency_conditions.build()
    else
      if params[:add_row]
        @question = Question.new
        @question.build_dependency(:rule=>'A').dependency_conditions.build()
      end
    end
    render :partial => 'dependency_condition_fields'
  end

  def get_answers
    options=""
    question_id =  params[:question_id]
    question = Question.find(question_id)
    if question && question.answers
      question.answers.each_with_index do |a, index|
        options += '<option ' +
         (index == 0 ? 'selected="selected" ' : '') +
         'value="' + a.id.to_s + '"' +
         '>'+a.text.to_s+"</option>"
      end
    end
    render :inline=>options
  end

  def get_question_type
    question_id =  params[:question_id]
    question = Question.find(question_id)
    response=question.pick
    response += ','+question.question_type
    render :inline=>response
  end

private

  def prep_variables
    @question = Question.includes(:dependency).find(params[:id]) unless @question
    controlling_questions = get_controlling_question_collection(@question)
    @controlling_questions = controlling_questions.collection
    @this_question = controlling_questions.dependency_question_description
    @operators = get_operators
    answer = Question.find(@controlling_questions.last[1]).answers
    @answers = answer.map{|a| [a.text, a.id]}
  end

  def get_controlling_question_collection(question)
    survey_id = _get_survey_id(question)
    all_questions = _get_all_questions_in_survey(survey_id)
    _get_question_collection(all_questions, question)
  end

  def _get_survey_id(question)
    question.survey_section.survey.id
  end

  def _get_all_questions_in_survey(survey_id)
    Question.unscoped
      .joins(:survey_section)
      .where('survey_id = ?', survey_id)
      .order('survey_sections.display_order','survey_sections.id','questions.display_order')
  end

  def _get_question_collection(all_questions, question_with_dependencies)
    controlling_questions = QuestionCollection.new(question_with_dependencies)
    all_questions.each{|q| controlling_questions.add_question(q) }
    controlling_questions
  end

  def get_operators
    return [
      ['equal to (=)','=='],
      ['not equal to','!='],
      ['less than (<)','<'],
      ['less than or equal to (<=)','<='],
      ['greater than or equal to (>=)','>='],
      ['greater than','>']
    ]
  end
end

class QuestionCollection
  attr_accessor :collection, :dependency_question_description

  def initialize(question_with_dependencies)
    @collection = []
    @question_number = 1
    @question_with_dependencies = question_with_dependencies
    @dependency_question_description = nil
  end

  def collection
    @collection
  end

  def add_question(question)
    unless question.id == @question_with_dependencies.id
      _add_to_collection_if_eligible(question)
    else
      _handle_dependency_question(question)
    end
  end

  private
  def _handle_dependency_question(question)
    _set_dependency_question_description(question)
    _increment_question_number if _eligible_question?(question)
  end

  def _set_dependency_question_description(question)
    @dependency_question_description = _eligible_question?(question) ? _get_description(question) : question.text
  end

  def _get_description(question)
    @question_number.to_s + ') ' + question.text
  end

  def _add_to_collection(question)
    description = _get_description(question)
    @collection.push([description, question.id])
  end

  def _add_to_collection_if_eligible(question)
    if _eligible_question?(question)
      _add_to_collection(question)
      _increment_question_number
    end
  end

  def _eligible_question?(question)
    question.question_type!='Label' && question.question_type!='File Upload'
  end

  def _increment_question_number
    @question_number += 1
  end
end
