
class DependencyCondition < ActiveRecord::Base
  include Surveyor::Models::DependencyConditionMethods

  attr_accessor :rule_key_temp, :join_operator
  attr_accessible :dependency_id, :rule_key, :question_id, :operator, :answer_id, :rule_key_temp, :join_operator, :float_value, :integer_value
  belongs_to :dependency
  default_scope :order => 'rule_key'

  def rule_key_temp
    if self.rule_key
      return rule_key
    else
      if self.dependency
        last_key = self.dependency.dependency_conditions.maximum(:rule_key)
      else
        last_key = ''
      end
      if last_key.is_number?
        return rule_key.to_i + 1
      else
        return 0
      end
    end
  end

  def rule_key_temp=(rk)
    self.rule_key = rk
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

end
class String
  def is_number?
    true if Float(self) rescue false
  end
end
