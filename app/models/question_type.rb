class QuestionType
  unloadable
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  
  include SurveyorGui::Models::QuestionTypeMethods

end
