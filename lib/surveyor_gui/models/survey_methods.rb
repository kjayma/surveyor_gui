module SurveyorGui
  module Models
    module SurveyMethods
      def self.included(base)
        base.extend Surveyor::Models::SurveyMethods
        base.send :attr_accessible, :title, :access_code, :template,
                        :survey_sections_attributes if defined? ActiveModel::MassAssignmentSecurity
        base.send :has_many, :survey_sections, :dependent => :destroy
        base.send :accepts_nested_attributes_for, :survey_sections, :allow_destroy => true

        base.send :validate, :no_responses
        base.send :before_destroy, :no_responses, prepend: true

      end


      #don't let a survey be deleted or changed if responses have been submitted
      #to ensure data integrity
      def no_responses
        if self.id
          #this will be a problem if two people are editing the survey at the same time and do a survey preview - highly unlikely though.
          self.response_sets.where('test_data = ?',true).each {|r| r.destroy}
        end
        if !template && response_sets.count>0
          errors.add(:base,"Responses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
          return false
        end
      end

    end
  end
end
