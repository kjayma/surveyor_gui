class SurveyformsController < ApplicationController
  unloadable
  include Surveyor::SurveyorControllerMethods
  include SurveyorGui::SurveyformsControllerMethods
end
