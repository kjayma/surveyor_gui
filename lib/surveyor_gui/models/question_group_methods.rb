module SurveyorGui
  module Models
    module QuestionGroupMethods

      def self.included(base)   
        base.send :accepts_nested_attributes_for, :questions, :allow_destroy => true  
        base.send :has_many, :columns    
        base.send :accepts_nested_attributes_for, :columns,  :allow_destroy => true  
      end
            
      def trim_columns(qty_to_trim)
        columns = self.columns.order('id ASC')
        columns.last(qty_to_trim).map{|c| c.destroy}
      end
      
      def controlling_questions
        dependencies = []
        dependencies << self.dependency
        dependencies.map{|d| d.dependency_conditions.map{|dc| dc.question}}.flatten.uniq
      end
    end
  end
end
