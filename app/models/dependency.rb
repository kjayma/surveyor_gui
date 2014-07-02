class Dependency < ActiveRecord::Base
  include Surveyor::Models::DependencyMethods
  include SurveyorGui::Models::DependencyMethods
end
