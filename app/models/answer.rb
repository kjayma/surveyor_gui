class Answer < ActiveRecord::Base
  include Surveyor::Models::AnswerMethods
  include SurveyorGui::Models::AnswerMethods
end
