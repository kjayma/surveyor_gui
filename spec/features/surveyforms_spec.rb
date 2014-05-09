require 'spec_helper'

def start_a_new_survey
  visit new_surveyform_path
  fill_in "Title", with: "How was Boston?"
  click_button "Save Changes"
end

def first_section_title
  find('.survey_section h2')
end

def first_question
  find('.question span.questions')
end

def add_question
  click_button "Add Question"
  expect(page).to have_css('iframe')
  within_frame 0 do
    find('form')
    expect(find('h1')).to have_content("Add Question")
  end
end

def select_question_type(type)
  within ".question_question_type" do
    choose(type)
  end
end

def answers
  wait_for_ajax
  page.all("div.answer .question_answers_text input")
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
    before :each do
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

    scenario "User adds a text question", :js=>true do
      #Given I've started a new survey
      #When I click the "Add Question" button
      click_button "Add Question"

      #Then I see a window pop-up
      expect(page).to have_css('iframe')
      within_frame 0 do

      #And I see a new form for "Add Question"
        find('form')
        expect(find('h1')).to have_content("Add Question")

      #And I frame the question
        fill_in "question_text", with: "Where did you stay?"

      #And I select the "text" question type
        select_question_type "Text"

      #And I save the question
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the question in my survey
      expect(first_question).to have_content("Where did you stay?")
      expect(page).to have_css("input[type='text']")
    end
  end

  context "User is building up the survey" do
    before :each do
      start_a_new_survey
      add_question
    end
    scenario "User adds a number question", :js=>true do
      #Given I've added a new question
      within_frame 0 do

      #Then I select the "number" question type
        select_question_type "Number"

      #And I frame the question
        fill_in "question_text", with: "How many days did you stay?"

      #And I add the suffix, "days"
        fill_in "question_suffix", with: "days"

      #And I sav the question
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the question in my survey
      expect(first_question).to have_content("How many days did you stay?")
      expect(page).to have_css("input[type='text']")
      expect(page).to have_content("days")
    end


    scenario "User adds a multiple choice question", :js=>true do
      #Given I've added a new question
      within_frame 0 do

      #Then I select the "number" question type
        select_question_type "Multiple Choice (only one answer)"

      #And I frame the question
        fill_in "question_text", with: "What type of room did you get?"

      #And I add some choices"
        answers[0].set("Deluxe King")
        find(".add_answer img").click
        answers[1].set("Standard Queen")
        find(".add_answer img").click
        answers[2].set("Standard Double")

      #And I save the question
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the question in my survey
      expect(first_question).to have_content("What type of room did you get?")
      expect(page).to have_css("input[type='radio'][value='Deluxe King']")
      expect(page).to have_css("input[type='radio'][value='Standard Queen']")
      expect(page).to have_css("input[type='radio'][value='Standard Double']")
    end


    scenario "User adds a choose any question", :js=>true do
      #Given I've added a new question
      within_frame 0 do

      #Then I select the "number" question type
        select_question_type "Multiple Choice (multiple answers)"

      #And I frame the question
        fill_in "question_text", with: "What did you order from the minibar?"

      #And I add some choices"
        answers[0].set("Bottled Water")
        find(".add_answer img").click
        answers[1].set("Kit Kats")
        find(".add_answer img").click
        answers[2].set("Scotch")

      #And I save the question
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the question in my survey
      expect(first_question).to have_content("What did you order from the minibar?")
      expect(page).to have_css("input[type='checkbox'][value='Bottled Water']")
      expect(page).to have_css("input[type='checkbox'][value='Kit Kats']")
      expect(page).to have_css("input[type='checkbox'][value='Scotch']")
    end


    scenario "User adds a dropdown list", :js=>true do
      #Given I've added a new question
      within_frame 0 do

      #Then I select the "number" question type
        select_question_type "Dropdown List"

      #And I frame the question
        fill_in "question_text", with: "What neighborhood were you in?"

      #And I add some choices"
        answers[0].set("Financial District")
        find(".add_answer img").click
        answers[1].set("Back Bay")
        find(".add_answer img").click
        answers[2].set("North End")

      #And I save the question
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the question in my survey
      expect(first_question).to have_content("What neighborhood were you in?")
      expect(page).to have_css("option[value='Financial District']")
      expect(page).to have_css("option[value='Back Bay']")
      expect(page).to have_css("option[value='North End']")
    end


    scenario "User adds a date question", :js=>true, :wip=>true do
      #Given I've added a new question
      within_frame 0 do

      #Then I select the "number" question type
        select_question_type "Date"

      #And I frame the question
        fill_in "question_text", with: "When did you checkout?"

      #And I save the question
        click_button "Save Changes"

      #Then the window goes away
      end

      #And I can see the question in my survey
      expect(first_question).to have_content("When did you checkout?")
      expect(page).to have_css("div.ui-datepicker",:visible=>false)

      #Then I click on the question
      1.times {page.execute_script "$('input.date_picker').trigger('focus')"}

      #And I see a datepicker popup
      expect(page).to have_css("div.ui-datepicker", :visible=>true)
    end
  end
end
