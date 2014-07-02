class Question < ActiveRecord::Base
  include Surveyor::Models::QuestionMethods
  include SurveyorGui::Models::QuestionMethods
end
