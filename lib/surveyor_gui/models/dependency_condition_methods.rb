module SurveyorGui
  module Models
    module DependencyConditionMethods

      def self.included(base)
        base.send :attr_accessible, :dependency_id, :rule_key, :question_id, :operator, :answer_id,
                  :float_value, :integer_value, :join_operator
        base.send :belongs_to, :dependency
        base.send :default_scope, :order => 'rule_key'
      end

      def join_operator
        if self.dependency
          rule = self.dependency.rule
          if rule
            rarray = rule.split(' ')
            idx = rarray.find_index{|i| i == self.rule_key}
            if idx && idx > 0
              return rarray[idx-1]
            else
              return nil
            end
          end
        end
      end

      def join_operator=(x)
      end

    end
    class String
      def is_number?
        true if Float(self) rescue false
      end
    end
  end
end
