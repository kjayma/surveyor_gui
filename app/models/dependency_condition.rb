class DependencyCondition < ActiveRecord::Base
  unloadable
  include Surveyor::Models::DependencyConditionMethods
  include SurveyorGui::Models::DependencyConditionMethods
end
