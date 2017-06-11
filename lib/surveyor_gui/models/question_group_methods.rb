module SurveyorGui

  module Models

    module QuestionGroupMethods

      include QuestionAndGroupSharedMethods


      def self.included(base)

        base.send :attr_accessor, :is_mandatory, :survey_section_id

        base.send :attr_writer, :question_id

        base.send :attr_accessible, :questions_attributes if defined? ActiveModel::MassAssignmentSecurity

        base.send :accepts_nested_attributes_for, :questions, :allow_destroy => true

        base.send :has_many, :columns


        base.send( :default_scope, -> { base.includes(:columns, :questions ) } )


        base.send :accepts_nested_attributes_for, :columns, :allow_destroy => true

        base.send :accepts_nested_attributes_for, :dependency, :reject_if => lambda { |d| d[:rule].blank? }, :allow_destroy => true


      end


      def answers
        questions.includes(:answers).flat_map(&:answers)
      end


      def responses_in_set( response_set )
        questions.includes(:responses).joins(:responses).where('responses.response_set_id = ?', response_set.id)
      end


      def question_type_id

        if !@question_type_id
          @question_type = case display_type
                             when "inline"
                               :group_inline
                             when "default"
                               :group_default
                             when "repeater"
                               :repeater
                           end
        else
          @question_type_id
        end
      end


      def question_type_id=(question_type_id)

        case question_type_id
          when "group_default"
            write_attribute(:display_type, "default")
          when "group_inline"
            write_attribute(:display_type, "inline")
          when "repeater"
            write_attribute(:display_type, "repeater")
        end

        @question_type_id = question_type_id

      end


      def trim_columns(qty_to_trim)

        columns = self.columns.order('id ASC')
        columns.last(qty_to_trim).map { |c| c.destroy }

      end


      def question_id
        self.questions.first.id if self.questions.first
      end

      #def controlling_questions in QuestionAndGroupSharedMethods
    end
  end

end
