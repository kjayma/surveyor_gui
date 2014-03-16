module Surveyor
  module Models
    module AnswerMethods

      def self.included(base)
        base.send :belongs_to, :question
        base.send :has_many, :responses
        base.send :attr_accessible, :text, :response_class, :display_order, :original_choice, :hide_label, :question_id, :display_type

        base.send :before_save, :update_display_order
      end

      #maintain a display order for questions
      def update_display_order
        answer_count = self.question.answers.count
        if answer_count > 0
          if self.display_order == 0
            self.display_order = self.question.answers.maximum(:display_order)
          end
        end
      end

      def split_or_hidden_text(part = nil)
        #return "" if hide_label.to_s == "true"
        return "" if display_type.to_s == "hidden_label"
        part == :pre ? text.split("|",2)[0] : (part == :post ? text.split("|",2)[1] : text)
      end

    end
  end
end
