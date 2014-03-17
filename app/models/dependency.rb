class Dependency < ActiveRecord::Base
  unloadable
  include Surveyor::Models::DependencyMethods
  include SurveyorGui::Models::DependencyMethods
end
