require 'spec_helper'

#from spec/support/surveyforms_helpers.rb
include SurveyFormsCreationHelpers::CreateSurvey
include SurveyFormsCreationHelpers::BuildASurvey

feature "Survey Creator rearranges survey",  %q{
  As a Survey Creator
  I want to rearrange a survey
  So that I can change my mind if I don't like the order of sections and questions} do

  #force a cr/lf to make the output look better
  scenario " " do
  end
  context "Survey creator rearranges questions", :js=>true do
    before :each do
      build_a_three_question_survey
    end

    #include helpers to simulate Cucumber type Scenario Outline.
    #Found in spec/support/surveyforms_rearrangement_helpers.rb
    include_context "question_cut_and_paste"

    #Given that my survey has  unique questions 1, 2, and 3 in order
    #When I cut <from_item> and paste it <over_under> <to_item>
    #Then I see questions in the correct <order>
    #|from_item     | over_under | to_item     | order|
    #|2             | over       | 1           | 213  |
    #|2             | over       | 3           | 123  |
    #|2             | under      | 1           | 123  |
    #|2             | under      | 3           | 132  |
    #|1             | over       | 2           | 312  |
    #|1             | over       | 3           | 132  |
    #|1             | under      | 2           | 321  |
    #|1             | under      | 3           | 312  |
    #|3             | over       | 1           | 312  |
    #|3             | over       | 2           | 132  |
    #|3             | under      | 1           | 132  |
    #|3             | under      | 2           | 123  |

    scenario "Survey Creator cuts and pastes questions" do
      run_scenario
    end
  end

  context "Survey creator rearranges sections", :js=>true do
    before :each do
      build_a_three_section_survey
    end

    #include helpers to simulate Cucumber type Scenario Outline.
    #Found in spec/support/surveyforms_rearrangement_helpers.rb
    include_context "section_cut_and_paste"

    #Given that my survey has  unique sections 1, 2, and 3 in order
    #When I cut <from_item> and paste it <over_under> <to_item>
    #Then I see sections in the correct <order> per same table as used for questions
    scenario "Survey Creator cuts and pastes sections" do
      run_scenario
    end
  end

  context "Survey creator rearranges questions and sections together", :js=>true do
    before :each do
      build_a_survey
    end

    include_context "question_and_section_cut_and_paste"
    scenario "Survey Creator cuts and pastes questions and sections" do
      #Given that my survey has questions in the wrong sections
      #and sections in the wrong order:
      puts """
        started with this survey:
          Accommodations:
            Describe your day at Fenway Park.
          Entertainment:
            Describe your room.
          Food:                                """
      expect(page).to have_content(Regexp.new(
        """
        Accommodations.*
          Describe your day at Fenway Park\..*
        Entertainment.*
          Describe your room\..*
        Food
        """.gsub(/\n\s*/,"").strip
        ))

      #When I move questions to the appropriate sections
      cut_question("Describe your day at Fenway Park.")
      paste_question("over", "Describe your room.")
      cut_question("Describe your room.")
      paste_question("under", "How many days did you stay?")

      #And I arrange sections in the appropriate order
      cut_section("Accommodations")
      paste_section("under", "Food")

      #Then the survey is organized correctly:
      puts """
        ended with this survey:
          Entertainment:
            Describe your day at Fenway Park.
          Food:
          Accommodations:
            Describe your room.                   """
      expect(page).to have_content(Regexp.new(
        """
        Entertainment.*
          Describe your day at Fenway Park\..*
        Food.*
        Accommodations.*
          Describe your room\.
        """.gsub(/\n\s*/,"").strip
        ))
    end
  end
end
