class ResponseSet < ActiveRecord::Base
  include Surveyor::Models::ResponseSetMethods
  include SurveyorGui::Models::ResponseSetMethods
end
