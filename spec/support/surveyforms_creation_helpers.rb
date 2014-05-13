module SurveyFormsCreationHelpers
  module CreateSurvey
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
  end

  module BuildASurvey
    def build
      visit new_surveyform_path
      #When I fill in a title
      fill_in "Title", with: "How was Boston?"
      #And I save the survey
      click_button "Save Changes"
      #And I click "Edit Section Title"
      click_button "Edit Section Title"
      #Then I see a window pop-up
      expect(page).to have_css('iframe')
      within_frame 0 do
      #And I enter a title
        fill_in "Title", with: "Accommodations"
      #And I save the title
        click_button "Save Changes"
      end
      add_question
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
      add_question
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
      add_question
      within_frame 0 do
      #Then I select the "multiple choice" question type
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
      #Given I've added a new question
      add_question
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
      #Given I've added a new question
      add_question
      within_frame 0 do
      #Then I select the "number" question type
        select_question_type "Dropdown List"
      #And I frame the question
        fill_in "question_text", with: "1) What neighborhood were you in?"
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
      #Given I've added a new question
      add_question
      within_frame 0 do
      #Then I select the "number" question type
        select_question_type "Date"
      #And I frame the question
        fill_in "question_text", with: "When did you checkout?"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
      #Given I've added a new question
      add_question
      within_frame 0 do
      #Then I select the "Text Box" question type
        select_question_type "Text Box (for extended text, like notes, etc.)"
      #And I frame the question
        fill_in "question_text", with: "What did you think of the staff?"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
      #Given I've added a new question
      add_question
      within_frame 0 do
      #Then I select the "Text Box" question type
        select_question_type "Slider"
      #And I frame the question
        fill_in "question_text", with: "What did you think of the food?"
      #And I add some choices"
        answers[0].set("Sucked!")
        find(".add_answer img").click
        answers[1].set("Meh")
        find(".add_answer img").click
        answers[2].set("Good")
        find(".add_answer img").click
        answers[3].set("Wicked good!")
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
      #Given I've added a new question
      add_question
      within_frame 0 do
      #Then I select the "Star" question type
        select_question_type "Star"
      #And I frame the question
        fill_in "question_text", with: "How would you rate your stay?"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
      #Given I've added a new question
      add_question
      within_frame 0 do
      #Then I select the "Star" question type
        select_question_type "File Upload"
      #And I frame the question
        fill_in "question_text", with: "Please upload a copy of your bill."
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end
  end
end
