PermittedParams.class_eval do
  def gui_params
    SurveyorGui::PermittedParams.new
  end

  alias_method :base_answer_attributes, :answer_attributes
  def answer_attributes
    base_answer_attributes + gui_params.answer_attributes
  end

  alias_method :base_question_attributes, :question_attributes
  def question_attributes
    base_question_attributes+ gui_params.question_attributes
  end

  alias_method :base_dependency_attributes, :dependency_attributes
  def dependency_attributes
    base_dependency_attributes + gui_params.dependency_attributes
  end

  alias_method :base_dependency_condition_attributes, :dependency_condition_attributes
  def dependency_condition_attributes
    base_dependency_condition_attributes + gui_params.dependency_condition_attributes
  end

  alias_method :base_response_attributes, :response_attributes
  def response_attributes
    base_response_attributes + gui_params.response_attributes
  end

  alias_method :base_response_set_attributes, :response_set_attributes
  def response_set_attributes
    base_response_set_attributes + gui_params.response_set_attributes
  end

  alias_method :base_survey_attributes, :survey_attributes
  def survey_attributes
    base_survey_attributes + gui_params.survey_attributes
  end

  alias_method :base_survey_section_attributes, :survey_section_attributes
  def survey_section_attributes
    base_survey_section_attributes + gui_params.survey_section_attributes
  end

end