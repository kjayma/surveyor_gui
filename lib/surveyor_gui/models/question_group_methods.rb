module SurveyorGui
  module Models
    module QuestionGroupMethods

      def self.included(base)   
        base.send :accepts_nested_attributes_for, :questions, 
                  :reject_if => lambda { |d| d[:rule].blank?}, :allow_destroy => true  
        base.send :has_many, :columns    
        base.send :accepts_nested_attributes_for, :columns, 
                  :reject_if => lambda { |d| d[:rule].blank?}, :allow_destroy => true  
      end
    end
  end
end
