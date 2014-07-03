class DependencyCondition < ActiveRecord::Base
  include Surveyor::Models::DependencyConditionMethods
  include SurveyorGui::Models::DependencyConditionMethods
end
