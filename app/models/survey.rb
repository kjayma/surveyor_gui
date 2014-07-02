class Survey < ActiveRecord::Base
  include Surveyor::Models::SurveyMethods
  include SurveyorGui::Models::SurveyMethods
end
