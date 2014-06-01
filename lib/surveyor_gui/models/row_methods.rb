module SurveyorGui
  module Models
    module RowMethods

      def self.included(base)
        base.send :belongs_to, :question_group
        base.send :attr_accessible, :text, :question_group_id if defined? ActiveModel::MassAssignmentSecurity
      end
    end
  end
end
