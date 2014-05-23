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

    def add_question(&block)
      #make sure prior jquery was completed
      expect(page).not_to have_css('div.jquery_add_question_started, div.jquery_add_section_started')
      fix_node_error do
        all('#add_question').last.click
        expect(page).to have_css('iframe')
      end
      within_frame 0 do
      #then wait for window to pop up
        find('form')
        expect(find('h1')).to have_content("Add Question")
      #then enter the question details
        block.call
      #then the window closes
      end
      expect(page).not_to have_css('div.jquery_add_question_started')
    end

    def add_section
      fix_node_error do
        all('#add_section').last.click
        expect(page).to have_css('iframe')
      end
    end

    def fix_node_error(&block)
      # fix Capybara::Poltergeist::ObsoleteNode: - seems like some kind of race problem
      begin
        yield(block)
      rescue
        sleep(1)
        yield(block)
      end
    end

    def select_question_type(type)
      within ".question_question_type" do
        choose(type)
      end
    end

    def add_answers
      wait_for_ajax
      page.all("div.answer .question_answers_text input")
    end
  end

  module BuildASurvey
    def build_a_survey
      #Given I'm on the "Create New Survey" page
      visit new_surveyform_path

      title_the_survey
      title_the_first_section
      add_a_text_question("Describe your day at Fenway Park.")
      add_a_number_question
      add_a_pick_one_question
      add_a_pick_any_question
      add_a_dropdown_question
      add_a_date_question
      add_a_label
      add_a_slider_question
      add_a_star_question
      add_a_file_upload

      add_a_new_section("Entertainment")
      question_maker = QuestionsFactory.new
      question_maker.make_question(3){|text| add_a_text_question(text)}
      add_a_text_question("Describe your room.")

      add_a_new_section("Food")
      question_maker.make_question(3){|text| add_a_text_question(text)}
    end

    def build_a_three_question_survey
      visit new_surveyform_path
      title_the_survey
      question_maker = QuestionsFactory.new
      question_maker.make_question(3){|text| add_a_text_question(text)}
    end

    def build_a_three_section_survey
      visit new_surveyform_path
      title_the_survey
      title_the_first_section ("Unique Section 1")
      add_a_new_section("Unique Section 2")
      add_a_new_section("Unique Section 3")
    end

    def title_the_survey
      #When I fill in a title
      fill_in "Title", with: "How was Boston?"
      #And I save the survey
      click_button "Save Changes"
    end

    def title_the_first_section(title="Accommodations")
      #And I click "Edit Section Title"
      click_button "Edit Section Title"
      #Then I see a window pop-up
      expect(page).to have_css('iframe')
      within_frame 0 do
      #And I enter a title
        fill_in "Title", with: title
      #And I save the title
        click_button "Save Changes"
      end
    end

    def add_a_text_question(text="Where did you stay?")
      add_question do
      #And I see a new form for "Add Question"
        find('form')
        expect(find('h1')).to have_content("Add Question")
      #And I frame the question
        fill_in "question_text", with: text
      #And I select the "text" question type
        select_question_type "Text"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_number_question
      add_question do
      #Given I've added a new question
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
    end

    def add_a_pick_one_question
      add_question do
      #Then I select the "multiple choice" question type
        select_question_type "Multiple Choice (only one answer)"
      #And I frame the question
        fill_in "question_text", with: "What type of room did you get?"
      #And I add some choices"
        fill_in "question_answers_textbox", with: """Deluxe King
                                                   Standard Queen
                                                   Standard Double"""
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_pick_any_question
      #Given I've added a new question
      add_question do
      #Then I select the "number" question type
        select_question_type "Multiple Choice (multiple answers)"
      #And I frame the question
        fill_in "question_text", with: "What did you order from the minibar?"
      #And I add some choices"
        fill_in "question_answers_textbox", with: """Bottled Water
                                                   Kit Kats
                                                   Scotch"""
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_dropdown_question
      #Given I've added a new question
      add_question do
      #Then I select the "number" question type
        select_question_type "Dropdown List"
      #And I frame the question
        fill_in "question_text", with: "What neighborhood were you in?"
      #And I add some choices"
        fill_in "question_answers_textbox", with: """ Financial District
                                                    Back Bay
                                                    North End"""
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_date_question
      #And I can see the question in my survey
      #Given I've added a new question
      add_question do
      #Then I select the "number" question type
        select_question_type "Date"
      #And I frame the question
        fill_in "question_text", with: "When did you checkout?"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_label
      add_question do
      #Then I select the "Label" question type
        select_question_type "Label"
      #And I frame the question
        fill_in "question_text", with: "You don't need to answer the following questions if you are not comfortable."
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_text_box_question
      #Given I've added a new question
      add_question do
      #Then I select the "Text Box" question type
        select_question_type "Text Box (for extended text, like notes, etc.)"
      #And I frame the question
        fill_in "question_text", with: "What did you think of the staff?"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_slider_question
      #Given I've added a new question
      add_question do
      #Then I select the "Slider" question type
        select_question_type "Slider"
      #And I frame the question
        fill_in "question_text", with: "What did you think of the food?"
      #And I add some choices"
        fill_in "question_answers_textbox", with: """Sucked!
                                                   Meh
                                                   Good
                                                   Wicked good!"""  
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_star_question
      #Given I've added a new question
      add_question do
      #Then I select the "Star" question type
        select_question_type "Star"
      #And I frame the question
        fill_in "question_text", with: "How would you rate your stay?"
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_file_upload
      #Given I've added a new question
      add_question do
      #Then I select the "Star" question type
        select_question_type "File Upload"
      #And I frame the question
        fill_in "question_text", with: "Please upload a copy of your bill."
      #And I save the question
        click_button "Save Changes"
      #Then the window goes away
      end
    end

    def add_a_new_section(title)
      #Then I add Section II
      add_section
      within_frame 0 do
        fill_in "Title", with: title
        click_button "Save Changes"
      end
    end

    class QuestionsFactory
      attr_reader :question_no
      def initialize
        @question_no = 1
      end

      def make_question(quantity,&block)
        quantity.times do
          block.call("Unique Question "+@question_no.to_s)
          @question_no += 1
        end
      end
    end
  end
end
