class Answer < ActiveRecord::Base
  unloadable
  include Surveyor::Models::AnswerMethods
  include SurveyorGui::Models::AnswerMethods
end
