module SurveyorGui
  module Models
    module AnswerMethods

      def self.included(base)
        base.send :belongs_to, :question
        base.send :has_many, :responses
        base.send :attr_accessible, *SurveyorGui::PermittedParams.new.answer_attributes if defined? ActiveModel::MassAssignmentSecurity
      end

      def split_or_hidden_text(part = nil)
        #return "" if hide_label.to_s == "true"
        return "" if display_type.to_s == "hidden_label"
        part == :pre ? text.split("|",2)[0] : (part == :post ? text.split("|",2)[1] : text)
      end

    end
  end
end
