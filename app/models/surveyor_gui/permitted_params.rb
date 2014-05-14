module SurveyorGui
  class PermittedParams < Struct.new(:params)

    def answer_attributes
      [:text, :response_class, :display_order, :original_choice, :hide_label,
       :question_id, :display_type]
    end

    def question_attributes
      [:dummy_answer, :question_type, :survey_section_id, :question_group, :text,
       :pick, :reference_identifier, :display_order, :display_type, :is_mandatory,
       :prefix, :suffix, :answers_attributes, :decimals, :dependency_attributes,
       :hide_label, :dummy_blob, :dynamically_generate, :dynamic_source,
       :modifiable, :report_code]
    end

    def dependency_attributes
      [:dependency_conditions_attributes]
    end

    def dependency_condition_attributes
      [:dependency_id, :rule_key, :question_id, :operator, :answer_id,
       :float_value, :integer_value, :join_operator]
    end

    def response_attributes
      [:response_set, :question, :answer, :date_value, :time_value,
       :response_set_id, :question_id, :answer_id, :datetime_value,
       :integer_value, :float_value, :unit, :text_value, :string_value,
       :response_other, :response_group, :survey_section_id, :blob]
    end

    def response_set_attributes
      [:survey, :responses_attributes, :user_id, :survey_id, :test_data]
    end

    def survey_attributes
      [:title, :access_code, :template, :survey_sections_attributes]
    end

    def survey_section_attributes
      [:title, :display_order, :questions_attributes, :survey_id, :modifiable]
    end
  end
end