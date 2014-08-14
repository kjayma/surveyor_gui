require 'surveyor/common'
module SurveyorGui
  module Models
    module ColumnMethods
      extend ActiveSupport::Concern
      include ActiveModel::Validations
      include Surveyor::MustacheContext
      include ActiveModel::ForbiddenAttributesProtection

      included do
        belongs_to :question_group
        has_many :answers
        attr_accessible *PermittedParams.new.column_attributes if defined? ActiveModel::MassAssignmentSecurity
      end
      def text_for(position = nil, context = nil, locale = nil)
      split(in_context(translation(locale)[:text], context), position)
      end
      def help_text_for(context = nil, locale = nil)
        in_context(translation(locale)[:help_text], context)
      end
      def split(text, position=nil)
        case position
        when :pre
          text.split("|",2)[0]
        when :post
          text.split("|",2)[1]
        else
          text
        end.to_s
      end
      def translation(locale)
        {:text => self.text, :help_text => self.help_text}.with_indifferent_access.merge(
          (self.question_group.questions.first.survey_section.translation(locale)[:columns] || {})[self.reference_identifier] || {}
        )
      end
      def help_text
        #stub
      end
      def reference_identifier
      end
    end
  end
end         
