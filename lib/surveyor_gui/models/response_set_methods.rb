module SurveyorGui
  module Models
    module ResponseSetMethods

      def self.included(base)
        base.send :has_many, :responses, :dependent=>:destroy
        base.send :attr_accessible, :survey, :responses_attributes, :user_id, :survey_id, :test_data if defined? ActiveModel::MassAssignmentSecurity
      end

      #determine whether a mandatory question is missing a response.  Only applicable if the question is not dependent on other questions,
      #or if it is dependent, but has been triggered for inclusion by a previous answer.
      def triggered_mandatory_missing
        qs = survey.sections.map(&:questions).flatten
        ds = Dependency.all(:include => :dependency_conditions, :conditions => {:dependency_conditions => {:question_id => qs.map(&:id) || responses.map(&:question_id)}})
        triggered = qs - ds.select{|d| !d.is_met?(self)}.map(&:question)
        triggered_mandatory = triggered.select{|q| q.mandatory?}
        triggered_mandatory_completed = triggered.select{|q| q.mandatory? and is_answered?(q)}
        triggered_mandatory_missing = triggered_mandatory - triggered_mandatory_completed
        return triggered_mandatory_missing
      end

      #return a hash of dependent questions.
      def all_dependencies(question_ids = nil)
            arr = dependencies(question_ids).partition{|d| d.is_met?(self) }
            {:show => arr[0].map{|d| d.question_group_id.nil? ? (d.question.is_mandatory? ? nil : "q_#{d.question_id}") : "g_#{d.question_group_id}"},
             :show_mandatory => arr[0].map{|d| d.question_group_id.nil? ? (d.question.is_mandatory? ? "q_#{d.question_id}" : nil) : "g_#{d.question_group_id}"},
             :hide => arr[1].map{|d| d.question_group_id.nil? ? "q_#{d.question_id}" : "g_#{d.question_group_id}"}}
      end
      def correctness_hash
        { :questions => Survey.where(id: self.survey_id).includes(sections: :questions).first.sections.map(&:questions).flatten.compact.size,
          :responses => responses.to_a.compact.size,
          :correct => responses.find_all(&:correct?).compact.size
        }
      end

      def report_user_name
        user_name = nil
        if defined? ResponseSetUser
          user_name = ResponseSetUser.new(self.id).report_user_name(self.user_id)
        end
        user_name || self.user_id || self.id
      end
    end
  end
end
