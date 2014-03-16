module Surveyor
  module Models
    module SurveyMethods

      def self.included(base)
        base.send :attr_accessible, :title, :access_code, :template,
                        :survey_sections_attributes
        base.send :has_many, :survey_sections, :dependent => :destroy
        base.send :accepts_nested_attributes_for, :survey_sections, :allow_destroy => true

        base.send :validate, :no_responses
        base.send :before_destroy, :no_responses

      end

      #don't let a survey be deleted or changed if responses have been submitted
      #to ensure data integrity
      def no_responses
        if self.id
          #this will be a problem if two people are editing the survey at the same time and do a survey preview - highly unlikely though.
          self.response_sets.where('test_data = ?',true).each {|r| r.destroy}
        end
        if !template && response_sets.count>0
          errors.add(:base,"Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
          return false
        end
      end

      #force unique titles by tacking a sequence to the end of duplicates
      def title=(value)
        return if value == self.title
        adjusted_value = value
        while Survey.find_by_access_code(Survey.to_normalized_string(adjusted_value))
          i ||= 0
          i += 1
          adjusted_value = "#{value} #{i.to_s}"
        end
        self.access_code = Survey.to_normalized_string(adjusted_value)
        super(adjusted_value)
       # self.access_code = Survey.to_normalized_string(value)
       # super
      end

    end
  end
end
