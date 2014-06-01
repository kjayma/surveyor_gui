module SurveyorGui
  module Models
    module ColumnMethods
      extend ActiveSupport::Concern
      include ActiveModel::Validations
      include ActiveModel::ForbiddenAttributesProtection

      included do
        belongs_to :question_group
        attr_accessible *PermittedParams.new.column_attributes if defined? ActiveModel::MassAssignmentSecurity
      end

    end
  end
end
