class Survey < ActiveRecord::Base
  unloadable
  include Surveyor::Models::SurveyMethods
  include SurveyorGui::Models::SurveyMethods
end
