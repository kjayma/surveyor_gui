# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveySection do
    let(:survey_section){ FactoryBot.create(:survey_section) }

  context "when creating" do
    it "validate: is invalid without #title" do
      survey_section.title = nil
      #survey_section.should have(1).error_on(:title)
      survey_section.valid?
      expect(survey_section.errors[:title].size).to eq(1)
    end
  end

  context "with questions" do
    let(:question_1){ FactoryBot.create(:question, :survey_section => survey_section, :display_order => 3, :text => "Peep")}
    let(:question_2){ FactoryBot.create(:question, :survey_section => survey_section, :display_order => 1, :text => "Little")}
    let(:question_3){ FactoryBot.create(:question, :survey_section => survey_section, :display_order => 2, :text => "Bo")}
    before do
      [question_1, question_2, question_3].each{|q| survey_section.questions << q }
    end
    it{ expect(survey_section.questions.count).to eq(3)}
    it "gets questions in order" do
      survey_section.questions.order("display_order asc").should == [question_2, question_3, question_1]
      survey_section.questions.order("display_order asc").map(&:display_order).should == [1,2,3]
    end
    it "deletes child questions when deleted" do
      question_ids = survey_section.questions.map(&:id)
      survey_section.destroy
      question_ids.each{|id| Question.find_by_id(id).should be_nil}
    end
  end

  context "with translations" do
    require 'yaml'
    let(:survey){ FactoryBot.create(:survey) }
    let(:survey_translation){
      FactoryBot.create(:survey_translation, :locale => :es, :translation => {
        :survey_sections => {
          :one => {
            :title => "Uno"
          }
        }
      }.to_yaml)
    }
    before do
      survey_section.reference_identifier = "one"
      survey_section.survey = survey
      survey.translations << survey_translation
    end
    it "returns its own translation" do
      YAML.load(survey_translation.translation).should_not be_nil
      survey_section.translation(:es)[:title].should == "Uno"
    end
    it "returns its own default values" do
      survey_section.translation(:de).should == {"title" => survey_section.title, "description" => survey_section.description}
    end
  end
end
