class SurveySection < ActiveRecord::Base
  include Surveyor::Models::SurveySectionMethods

  attr_accessible :title, :display_order,
                  :questions_attributes, :survey_id, :modifiable
  belongs_to :surveyform, :foreign_key=>:survey_id
  has_many :questions, :dependent => :destroy
  accepts_nested_attributes_for :questions
  default_scope :order => 'display_order'

  validate :no_responses
  before_destroy :no_responses

  #don't let a survey be deleted or changed if responses have been submitted
  #to ensure data integrity
  def no_responses
    if self.id && self.survey
      #this will be a problem if two people are editing the survey at the same time and do a survey preview - highly unlikely though.
      self.survey.response_sets.where('test_data = ?',true).each {|r| r.destroy}
    end
    if self.survey && !survey.template && survey.response_sets.count>0
      errors.add(:base,"Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
      return false
    end
  end
end
