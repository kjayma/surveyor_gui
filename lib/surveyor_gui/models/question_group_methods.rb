module SurveyorGui
  module Models
    module QuestionGroupMethods
      include QuestionAndGroupSharedMethods
      def self.included(base)
        base.send :attr_accessor, :is_mandatory, :survey_section_id
        base.send :attr_writer, :question_id
        base.send :attr_accessible, :questions_attributes if
                  defined? ActiveModel::MassAssignmentSecurity
        base.send :accepts_nested_attributes_for, :questions, :allow_destroy => true
        base.send :has_many, :columns
        base.send :accepts_nested_attributes_for, :columns,  :allow_destroy => true
        base.send :accepts_nested_attributes_for, :dependency, :reject_if => lambda { |d| d[:rule].blank?}, :allow_destroy => true
      end

      def question_type_id
        if display_type == "inline"
          :group_inline
        end
      end

      def question_type_id=(x)
      end

      def trim_columns(qty_to_trim)
        columns = self.columns.order('id ASC')
        columns.last(qty_to_trim).map{|c| c.destroy}
      end

      def question_id
        self.questions.first.id if self.questions.first
      end
      
      #def controlling_questions in QuestionAndGroupSharedMethods
    end
  end
end
