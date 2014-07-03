class QuestionType
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  include SurveyorGui::Models::QuestionTypeMethods

end
