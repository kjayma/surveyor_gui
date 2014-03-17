class Response < ActiveRecord::Base
  unloadable
  include Surveyor::Models::ResponseMethods
  include SurveyorGui::Models::ResponseMethods
end
