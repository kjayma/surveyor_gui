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
    @question = Question.new(question_params)
    if @question.save
      redirect_to :back
    else
      render :action => 'new', :layout=>'colorbox'
    end
  end

  def update
    @title = "Update Question"
    @question = Question.includes(:answers).find(params[:id])
    if @question.update_attributes(question_params)
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
    question_id               = params[:question_id]
    question                  = Question.find(question_id)
    column_id                 = params[:column_id].blank? ? _default_column_id(question) : params[:column_id]
    dependency_condition_id   = params[:dependency_condition_id]
    dependency_condition      = dependency_condition_id.blank? ? nil : DependencyCondition.find(dependency_condition_id)
    if question && question.answers
      question.answers.where('column_id = ? OR column_id IS NULL',column_id.to_i).each_with_index do |a, index|
        options += '<option ' + _get_selected_answer(index, dependency_condition, a, column_id) +
         'value="' + a.id.to_s + '"' +
         '>'+a.text.to_s+"</option>"
      end
    end
    render :inline=>options
  end
  
  def get_columns
    options=""
    question_id               = params[:question_id]
    dependency_condition_id   = params[:dependency_condition_id]
    dependency_condition      = dependency_condition_id.blank? ? nil : DependencyCondition.find(dependency_condition_id)
    question = Question.find(question_id)
    if question && question.question_group
      question.question_group.columns.each_with_index do |c, index|
        options += '<option ' +
         _get_selected_column(index, dependency_condition, c) +
         'value="' + c.id.to_s + '"' +
         '>'+c.text.to_s+"</option>"
      end
    end
    render :inline=>options
  end

  def get_question_type
    question_id =  params[:question_id]
    question = Question.find(question_id)
    response=question.pick
    response += ','+question.question_type_id.to_s
    response += ','+question_id
    render :inline=>response
  end

private

  def prep_variables
    @question = Question.includes(:dependency).find(params[:id]) unless @question
    controlling_questions = get_controlling_question_collection(@question)
    @controlling_questions = controlling_questions.collection
    @this_question = @question.question_description
    @operators = get_operators
  end

  def get_controlling_question_collection(dependent_question)
    all_questions_in_survey = _get_all_questions_in_survey(dependent_question)
    _get_question_collection(all_questions_in_survey, dependent_question)
  end

  def _get_all_questions_in_survey(question)
    PossibleControllingQuestion.unscoped
      .joins(:survey_section)
      .where('survey_id = ?', question.survey_section.survey_id)
      .order('survey_sections.display_order','survey_sections.id','questions.display_order')
  end

  def _get_question_collection(all_questions, dependent_question)
    return QuestionCollection.new(dependent_question).add_questions(all_questions)
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

  def question_params
    ::PermittedParams.new(params[:question]).question
  end
  
  def _default_column_id(question)
    if question.part_of_group?
      columns = question.question_group.columns
      columns.first ? columns.first.id.to_s : ""
    else
      ""
    end
  end
  
  def _get_selected_answer(index, dependency_condition, a, column_id)
    if _matches_dependency_condition(dependency_condition, a, column_id) 
      'selected="selected" ' 
    else 
      ''
    end  
  end
  
  def _get_selected_column(index, dependency_condition, column)
    if _matches_dependency_condition_column(dependency_condition, column) 
      'selected="selected"'
    else
      ''
    end
  end
  
  def _matches_dependency_condition (dependency_condition, a, column_id)
    if dependency_condition.nil?  
      false
    else
      (dependency_condition.answer_id == a.id && (column_id.blank? || dependency_condition.column_id == column_id.to_i ))
    end
  end
  
  def _matches_dependency_condition_column(dependency_condition, column)
    if dependency_condition.nil?
      false
    else
      dependency_condition.column_id == column.id
    end
  end
  
end

class QuestionCollection
  ## QuestionCollection provides a 2 dimensional array consisting of a question id
  ## and a question description.  The collection may be used in a view's select field.
  ##
  ## Its membership is determined by a base question.
  ## The base question is the one from which other questions in the collection are derived.
  ## E.g., in a dependency, the question that is shown or hidden based on the answers to others
  ## is the base question.  It shouldn't show up in the collection.
  ##
  ## Other questions may or may not show up in the collection depending on their eligibility.
  ##
  ## Some questions should have a question number and
  ## some should not. The QuestionCollection numbers questions that should be numbered
  ## and keeps track of the numbering.  If a question is numbered, the question number
  ## is included in the description, e.g. "3) What is your name?".  Otherwise,
  ## the description is just the question text, e.g. "Don't forget to use your middle initial".
  ##
  ## Incoming questions may be duck typed, but should respond to is_numbered? and is_eligible?
  ## messages.

  attr_accessor :collection, :dependency_question_description

  def initialize(base_question)
    @collection = []
    @question_number = 1
    @base_question = base_question
    @dependency_question_description = nil
  end

  def collection
    @collection
  end

  def add_questions(questions)
    questions.each {|q| add_question(q)}
    return self
  end

  def add_question(question)
    _add_to_collection_if_eligible(question)
    if question.is_numbered?
      _increment_question_number
    end 
    return self
  end

  private

  def _get_description(question)
    @question_number.to_s + ') ' + (question.part_of_group? ? question.question_group.text + ": " : "") +question.text
  end

  def _add_to_collection(question)
    description = _get_description(question)
    @collection.push([description, question.id])
  end

  def _add_to_collection_if_eligible(question)
    _add_to_collection(question) if question.is_eligible? && _this_is_not_the_base_question?(question)
  end

  def _this_is_not_the_base_question?(question)
    question.id != @base_question.id
  end

  def _increment_question_number
    @question_number += 1
  end
end

## This shouldn't be here but breaks saving nested attributes on question when put
## in QuestionMethods.  Not sure why, but leave for now and revisit later.
class PossibleControllingQuestion < Question
  def is_eligible?
    question_type_id!=:label && question_type_id!=:file
  end
end
