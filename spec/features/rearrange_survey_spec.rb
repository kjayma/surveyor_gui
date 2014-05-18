require 'spec_helper'

#from spec/support/surveyforms_helpers.rb
include SurveyFormsCreationHelpers::CreateSurvey
include SurveyFormsCreationHelpers::BuildASurvey

feature "User rearranges survey",  %q{
  As a user
  I want to rearrange a survey
  So that I can change my mind if I don't like the order of sections and questions} do

  #force a cr/lf to make the output look better
  scenario " " do
  end
  context "User rearranges questions", :js=>true do
    before :each do
      build_a_three_question_survey
    end

    #include helpers to simulate Cucumber type Scenario Outline.
    #Found in spec/support/surveyforms_rearrangement_helpers.rb
    include_context "question_cut_and_paste"

    #Given that my survey has  unique questions 1, 2, and 3 in order
    #When I cut <from_item> and paste it <over_under> <to_item>
    #Then I see questions in the correct <order>
    scenario "User cuts and paste questions" do
      run_scenario
    end
  end

  context "User rearranges sections", :js=>true do
    before :each do
      build_a_three_section_survey
    end

    #include helpers to simulate Cucumber type Scenario Outline.
    #Found in spec/support/surveyforms_rearrangement_helpers.rb
    include_context "section_cut_and_paste"

    #Given that my survey has  unique questions 1, 2, and 3 in order
    #When I cut <from_item> and paste it <over_under> <to_item>
    #Then I see questions in the correct <order>
    scenario "User cuts and paste sections" do
      run_scenario
    end
  end
end
