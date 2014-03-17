module SurveyorGui
  module Models
    module DependencyMethods
      def self.included(base)
        # Associations
        base.send :belongs_to, :question
        base.send :belongs_to, :question_group
        base.send :has_many, :dependency_conditions, :dependent => :destroy

        @@validations_already_included ||= nil
        unless @@validations_already_included
          # Validations
          base.send :validates_presence_of, :rule
          # base.send :validates_format_of, :rule, :with => /^(?:and|or|\)|\(|[A-Z]|\s)+$/ #TODO properly formed parenthesis etc.
          #base.send :validates_numericality_of, :question_id, :if => Proc.new { |d| !d.question_group_id.nil? }
          #base.send :validates_numericality_of, :question_group_id, :if => Proc.new { |d| !d.question_id.nil? }

          @@validations_already_included = true
        end

        # Attribute aliases
        base.send :alias_attribute, :dependent_question_id, :question_id
      end
    end
  end
end

class Dependency < ActiveRecord::Base
  include Surveyor::Models::DependencyMethods

  attr_accessor
  attr_accessible :question_id, :question_group, :rule, :dependency_conditions_attributes
  accepts_nested_attributes_for :dependency_conditions, :reject_if => lambda { |d| d[:operator].blank?}, :allow_destroy => true
  belongs_to :question
  validates_format_of :rule, :with => /^(?:and|or|\)|\(|[A-Z]|[0-9]+|\s)+$/ #TODO properly formed parenthesis etc.
end
