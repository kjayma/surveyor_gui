PermittedParams.class_eval do


  alias_method :base_answer_attributes, :answer_attributes
  def answer_attributes
    base_answer_attributes +
    [:text, :response_class, :display_order, :original_choice, :hide_label,
     :question_id, :display_type, :_destroy, :id]
  end

  alias_method :base_question_attributes, :question_attributes
  def question_attributes
    base_question_attributes +
    [:dummy_answer, :question_type, :survey_section_id, :question_group, :text,
     :pick, :reference_identifier, :display_order, :display_type, :is_mandatory,
     :prefix, :suffix, :decimals, :dependency_attributes, :id,
     :hide_label, :dummy_blob, :dynamically_generate, :dynamic_source,
     :modifiable, :report_code, :answers_textbox, answers_attributes: answer_attributes,
     dependency_attributes: dependency_attributes]
  end

  alias_method :base_dependency_attributes, :dependency_attributes
  def dependency_attributes
    base_dependency_attributes + [:dependency_conditions_attributes]
  end

  alias_method :base_dependency_condition_attributes, :dependency_condition_attributes
  def dependency_condition_attributes
    base_dependency_condition_attributes +
    [:dependency_id, :rule_key, :question_id, :operator, :answer_id,
     :float_value, :integer_value, :join_operator]
  end

  alias_method :base_response_attributes, :response_attributes
  def response_attributes
    base_response_attributes +
    [:response_set, :question, :answer, :date_value, :time_value,
     :response_set_id, :question_id, :answer_id, :datetime_value,
     :integer_value, :float_value, :unit, :text_value, :string_value,
     :response_other, :response_group, :survey_section_id, :blob]
  end

  alias_method :base_response_set_attributes, :response_set_attributes
  def response_set_attributes
    base_response_set_attributes +
    [:survey, :responses_attributes, :user_id, :survey_id, :test_data]
  end

  alias_method :base_survey_attributes, :survey_attributes
  def survey_attributes
    base_survey_attributes +
    [:title, :access_code, :template, :id,
      survey_sections_attributes: survey_section_attributes]
  end

  alias_method :base_survey_section_attributes, :survey_section_attributes
  def survey_section_attributes
    base_survey_section_attributes +
    [:title, :display_order, :questions_attributes, :survey_id, :modifiable,
     :id, questions_attributes: question_attributes]
  end

end
