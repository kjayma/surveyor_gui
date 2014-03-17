class ResponseSet < ActiveRecord::Base
  unloadable
  include Surveyor::Models::ResponseSetMethods
  include SurveyorGui::Models::ResponseSetMethods
end
