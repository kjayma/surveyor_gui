class SurveySection < ActiveRecord::Base
  include Surveyor::Models::SurveySectionMethods
  include SurveyorGui::Models::SurveySectionMethods
end
