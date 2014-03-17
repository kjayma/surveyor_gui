class Question < ActiveRecord::Base
  unloadable
  include Surveyor::Models::QuestionMethods
  include SurveyorGui::Models::QuestionMethods
end
