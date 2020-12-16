require 'spec_helper'
#from spec/support/surveyforms_helpers.rb
include SurveyFormsCreationHelpers::CreateSurvey
include SurveyFormsCreationHelpers::BuildASurvey

feature "User creates a dependency using browser", %q{
  As a user
  I want to create logic on questions
  So that I can display one question depending on the answer to another} do

  let!(:survey){FactoryBot.create(:survey, title: "Hotel ratings")}
  let!(:survey_section){FactoryBot.create(:survey_section, survey: survey)}
  let!(:question1) {FactoryBot.create(:question, survey_section: survey_section, text: "Rate the service")}
  let!(:answer1) {FactoryBot.create(:answer, question: question1, text: "yes", display_type: "default", response_class: "answer")}
  let!(:answer2) {FactoryBot.create(:answer, question: question1, text: "no", display_type: "default", response_class: "answer")}
  let!(:question2) {FactoryBot.create(:question, survey_section: survey_section, text: "Who was your concierge?")}
  let!(:answer2) {FactoryBot.create(:answer, question: question2)}
  before :each do
    question1.pick = "one"
    question1.save!
    question1.reload
  end

  scenario "user creates a dependency", js: true do
    #Given I have a survey with two questions
    visit surveyor_gui.surveyforms_path
    expect(page).to have_content("Hotel ratings")
    within "tr", text: "Hotel ratings" do
      click_link "Edit"
    end

    expect(page).to have_content("Rate the service")
    #And I click Add Logic on the second question
    within "fieldset.questions", text: "Who was your concierge" do
      click_button "Add Logic"
    end
    #Then I see a window pop-up
    expect(page).to have_css('iframe')
    within_frame 0 do
      #And it has logic, which defaults to checking the first question for the answer "yes"
      expect(page).to have_content("conditions")
      expect(page).to have_css("option", text: 'Rate the service')
      expect(page).to have_css("option", text: 'equal to')
      expect(page).to have_css("option", text: 'yes')
      click_button "Save Changes"
    end
    #Then I see that this survey has been updated to include a dependency
    expect(page).to have_content("This question is shown depending on the answer to question 1).")
    visit surveyor_path
    expect(page).to have_content("You may take these surveys")
    within "li", text: "Hotel ratings" do
      #And I take the newly created survey
      click_button "Take it"
    end
    expect(page).to have_content("Hotel ratings")
    expect(page).to have_content("Rate the service")
    expect(page).to have_css('input[type="radio"][value="'+answer1.id.to_s+'"]')
    #Then I don't see the second question just yet
    expect(page).not_to have_content("Who was your concierge?")
    #When I click yes as the answer to the first question
    choose "yes"
    #Then the second question magically appears
    expect(page).to have_content("Who was your concierge?")
  end
end
