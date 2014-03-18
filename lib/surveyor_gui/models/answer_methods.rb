module SurveyorGui
  module Models
    module AnswerMethods

      def self.included(base)
        base.send :belongs_to, :question
        base.send :has_many, :responses
        base.send :attr_accessible, :text, :response_class, :display_order,
                  :original_choice, :hide_label, :question_id, :display_type, :prefix, :suffix

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

      def dynamically_generate
        'false'
      end

      #number prefix getter.  splits a number question into the actual answer and it's unit type. Eg, you might want a
      #number to be prefixed with a dollar sign.
      def prefix
        if text && text.include?('|')
          text.split('|')[0]
        end
      end

      #number suffix getter. sometimes you want a number question to have a units of measure suffix, like "per day"
      def suffix
        if text && text.include?('|')
          text.split('|')[1]
        end
      end

      def prefix=(pre)
        write_attribute(:prefix,pre)
      end
      def suffix=(suf)
        write_attribute(:suffix,suf)
      end

     #sets the number prefix
      def text=(txt)
        if question && question.question_type=='Number'
            if attributes["prefix"].blank?
              write_attribute(:text, 'default')
            else
              write_attribute(:text, attributes["prefix"]+'|')
            end
            if !attributes["suffix"].blank?
              if text=='default'
                write_attribute(:text, '|'+attributes["suffix"])
              else
                write_attribute(:text, self.text+attributes["suffix"])
              end
            end
        else
          write_attribute(:text, txt)
        end
      end

    end
  end
end
