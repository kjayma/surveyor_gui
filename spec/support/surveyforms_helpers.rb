module SurveyFormsHelpers
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
end
