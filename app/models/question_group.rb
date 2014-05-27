class QuestionGroup < ActiveRecord::Base
  unloadable
  include Surveyor::Models::QuestionGroupMethods
  include SurveyorGui::Models::QuestionGroupMethods
end
