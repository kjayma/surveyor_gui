class Response < ActiveRecord::Base
  include Surveyor::Models::ResponseMethods
  include SurveyorGui::Models::ResponseMethods
end
