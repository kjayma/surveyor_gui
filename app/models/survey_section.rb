class SurveySection < ActiveRecord::Base
  unloadable
  include Surveyor::Models::SurveySectionMethods
  include SurveyorGui::Models::SurveySectionMethods
end
