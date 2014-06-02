module SurveyorGui
  module Models
    module QuestionGroupMethods

      def self.included(base)   
        base.send :accepts_nested_attributes_for, :questions, :allow_destroy => true  
        base.send :has_many, :columns    
        base.send :accepts_nested_attributes_for, :columns,  :allow_destroy => true  
      end
    end
  end
end
