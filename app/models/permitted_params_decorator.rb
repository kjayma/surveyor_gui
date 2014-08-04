PermittedParams.class_eval do


  alias_method :base_answer_attributes, :answer_attributes
  def answer_attributes
    base_answer_attributes +
    [:text, :response_class, :display_order, :original_choice, :hide_label,
     :question_id, :display_type, :_destroy, :id, :is_comment, :comment]
  end

  alias_method :base_question_attributes, :question_attributes
  def question_attributes
    base_question_attributes +
    [:question_type, :question_type_id, :survey_section_id, :question_group_id, :text,
     :text_adjusted_for_group,
     :pick, :reference_identifier, :display_order, :display_type, :is_mandatory,
     :prefix, :suffix, :decimals, :dependency_attributes, :id,
     :hide_label, :dummy_blob, :dynamically_generate, :dynamic_source,
     :omit_text, :omit, :other, :other_text, :is_comment, :comments, :comments_text,
     :modifiable, :report_code, :answers_textbox, :grid_columns_textbox, :_destroy,
     :grid_rows_textbox, :dropdown_column_count, :dummy_answer, dummy_answer_array: [], question_group_attributes: [:id, :display_type, columns_attributes: column_attributes, questions_attributes: [:id, :pick, :display_order, :display_type, :text, :question_type_id, :_destroy]],
     answers_attributes: answer_attributes,
     dependency_attributes: dependency_attributes]
  end

  alias_method :base_dependency_attributes, :dependency_attributes
  def dependency_attributes
    base_dependency_attributes + [:id, dependency_conditions_attributes: dependency_condition_attributes]
  end

  alias_method :base_dependency_condition_attributes, :dependency_condition_attributes
  def dependency_condition_attributes
    base_dependency_condition_attributes +
    [:id, :_destroy, :dependency_id, :rule_key, :question_id, :operator, :answer_id,
     :float_value, :integer_value, :join_operator, :column_id, column_attributes: column_attributes]
  end

  alias_method :base_response_attributes, :response_attributes
  def response_attributes
    base_response_attributes +
    [:response_set, :question, :answer, :date_value, :time_value,
     :response_set_id, :question_id, :answer_id, :datetime_value,
     :integer_value, :float_value, :unit, :text_value, :string_value,
     :response_other, :response_group, :survey_section_id, :blob, :comment]
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
  alias_method :base_question_group_attributes, :question_group_attributes
  def question_group_attributes
    base_question_group_attributes +
    [:id, :question_type, :question_type_id, :question_id, :survey_section_id, :is_mandatory, 
    columns_attributes: column_attributes, 
    dependency_attributes: dependency_attributes,questions_attributes: question_attributes]
  end
  # column
  def column
    strong_parameters.permit(*column_attributes)
  end
  def column_attributes
    [:id, :text, :question_group_id, :answers_textbox]
  end
end
