module SurveyorGui
  module Models
    module SurveySectionMethods

      def self.included(base)

        base.send :attr_accessible, :title, :display_order,
                        :questions_attributes, :survey_id, :modifiable if defined? ActiveModel::MassAssignmentSecurity
        base.send :belongs_to, :surveyform, :foreign_key=>:survey_id
        base.send :has_many, :questions, :dependent => :destroy
        base.send :accepts_nested_attributes_for, :questions
        base.send :default_scope, lambda{ base.order('display_order') }

        base.send :validate, :no_responses
        base.send :before_destroy, :no_responses, prepend: true
      end

      #don't let a survey be deleted or changed if responses have been submitted
      #to ensure data integrity
      def no_responses
        if self.id && self.survey
          #this will be a problem if two people are editing the survey at the same time and do a survey preview - highly unlikely though.
          self.survey.response_sets.where('test_data = ?',true).each {|r| r.destroy}
        end
        if self.survey && !survey.template && survey.response_sets.count>0
          errors.add(:base,"Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
          return false
        end
      end
    end
  end
end
