require 'spec_helper'

def start_a_new_survey
  visit new_surveyform_path
  fill_in "Title", with: "How was Boston?"
  click_button "Save Changes"
end

def first_section_title
  find('.survey_section h2')
end

feature "User creates a new survey using a browser",  %q{
  As a user
  I want to create a new survey using a browser
  So that I don't have to learn the Surveyor DSL or dive into technical weeds} do

  context "User has not yet started a new survey" do

    scenario "User starts a new survey" do
      #Given I'm on the surveyform web page
      visit surveyforms_path

      #When I click "New Survey"
      click_link "New Survey"

      #Then I see the "Create New Survey" page
      expect(page).to have_content("Create New Survey")
    end

    scenario "User gives the survey a title" do
      #Given I'm on the "Create New Survey" page
      visit new_surveyform_path

      #When I fill in a title
      fill_in "Title", with: "How was Boston?"

      #And I save the survey
      click_button "Save Changes"

      #Then I can start entering more details, like sections
      expect(page).to have_button "Add Section"

      #And questions
      expect(page).to have_button "Add Question"
    end
  end

  context "User started a new survey" do
    before(:each) do
      start_a_new_survey
    end

    scenario "User gives the section a title", :js=>true do
      #Given I've started a new survey
      #When I click the "Edit Section Title" button
      click_button "Edit Section Title"

      #Then I see a window pop-up
      expect(page).to have_css('iframe')
      within_frame 0 do

      #And I see a new form for "Edit Survey Section"
        find('form')
        expect(find('h1')).to have_content("Edit Survey Section")

      #And I enter a title
        fill_in "Title", with: "Accommodations"

      #And I save the title
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the correctly titled section in my survey
      expect(first_section_title).to have_content("Accommodations")
    end





  end
end
