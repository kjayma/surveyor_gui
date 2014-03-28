module SurveyorGui
  module Models
    module DependencyMethods
      def self.included(base)
        # Associations
        base.send :attr_accessible, :dependency_conditions_attributes
        base.send :accepts_nested_attributes_for, :dependency_conditions, :reject_if => lambda { |d| d[:operator].blank?}, :allow_destroy => true

#        # HACK: Remove the existing validates_numericality_of block.  By default in Surveyor, it doesn't account for
#        # question_id/question_group_id being nil when adding a new record - it never needed to.  However, Surveyor_gui
#        # adds accepts_nested_attributes_for dependency to the question model, which triggers the dependency validations
#        # This means we do need to account for adding new records, and the validation has to be modified.  Unfortunately,
#        # in Rails 3.2 there is no easy way to modify an existing validation.  We have to hack it out and replace it.
        base.class_eval do
          _validators.reject!{ |key, _| key == :question_id }

          _validate_callbacks.reject! do |callback|
            if callback.raw_filter.class==ActiveModel::Validations::NumericalityValidator
              [[:question_id], [:question_group_id]].include? callback.raw_filter.attributes
            end
          end
        end
        base.send :validates_numericality_of, :question_id, :if => Proc.new { |d| d.question_group_id.nil? && !d.new_record? }
        base.send :validates_numericality_of, :question_group_id, :if => Proc.new { |d| d.question_id.nil? && !d.new_record?}

        # Attribute aliases
        #base.send :alias_attribute, :dependent_question_id, :question_id
      end

      # need to overwrite the following methods because they rely on the nil? method.  Actually, the parameter comes back as a string
      # and even an empty string will not evaluate to nil.  Changed to blank? instead.
      def question_group_id=(i)
        write_attribute(:question_id, nil) unless i.blank? #i.nil?
        write_attribute(:question_group_id, i)
      end

      def question_id=(i)
        write_attribute(:question_group_id, nil) unless i.blank? #i.nil?
        write_attribute(:question_id, i)
      end
    end
  end
end

#class Dependency < ActiveRecord::Base
#  include Surveyor::Models::DependencyMethods
#
#  attr_accessible :question_id, :question_group, :rule, :dependency_conditions_attributes
#  accepts_nested_attributes_for :dependency_conditions, :reject_if => lambda { |d| d[:operator].blank?}, :allow_destroy => true
#  belongs_to :question
#  validates_format_of :rule, :with => /^(?:and|or|\)|\(|[A-Z]|[0-9]+|\s)+$/ #TODO properly formed parenthesis etc.
#end
