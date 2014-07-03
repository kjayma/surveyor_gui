class QuestionGroup < ActiveRecord::Base
  include Surveyor::Models::QuestionGroupMethods
  include SurveyorGui::Models::QuestionGroupMethods
end
