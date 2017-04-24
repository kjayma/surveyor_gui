require File.expand_path(File.dirname(__FILE__) + '/../spec_only_helper')

require File.join(__dir__, '..', '..','app','controllers','concerns', 'surveyor_gui_missing_info_flash_builder')


class MockController

  include SurveyorGui::MissingInfoFlashBuilder

  def t(something)
    "translated-#{something}"
  end

end

SectionMock = Struct.new(:title)

class QuestionMock

  def survey_section=(sec)
    @section = sec
  end

  def survey_section
    @section ||= SectionMock.new('sectionTitle')
  end

  def survey_section_id
    @survey_section_id ||= '1'
  end

  def survey_section_id=(i)
    @survey_section_id = i
  end

  def id
    @id ||= 0
  end

  def id=(i)
    @id = i
  end

  def text=(t)
    @t = t
  end

  def text
    @t ||= 'text'
  end
end



describe SurveyorGui::MissingInfoFlashBuilder do

  let(:mock_controller) { MockController.new }


  # build_main_missing_flash(missing_questions, displayed_q_numbers, joiner: '<br/>', wrapping_class: 'surveyor-missing-qs')
  describe "#build_main_missing_flash" do

    let(:missing_qs) { s1 = SectionMock.new('section1')
                          s2 = SectionMock.new('section2')

                          q1 = QuestionMock.new
                          q1.text = 'q1 text'
                          q1.id = 0
                          q1.survey_section = s1

                          q2 = QuestionMock.new
                          q2.id = 1
                          q2.text = 'q2 text'
                          q2.survey_section = s1

                          q3 = QuestionMock.new
                          q3.id = 1
                          q3.text = 'q3 text'
                          q3.survey_section = s1

                          q4 = QuestionMock.new
                          q4.id = 3
                          q4.text = 'q4 text'
                          q4.survey_section = s2

                          [q1, q2, q3, q4]
                        }

    let(:display_q_nums) {
                           {'0' => '1',
                            '1' => '2',
                            '2' => 'c',
                            '3' => 'iv'}
    }

    describe 'default wrapping class and join string' do

      let(:html_returned) { mock_controller.build_main_missing_flash(missing_qs, display_q_nums )}

      it 'wraps everything with a div and default CSS class' do
        expect(html_returned).to match(/<div class='surveyor-missing-qs'>(.*)<\/div>$/)
      end

      it '2 sections' do
        expect(html_returned.split("<span class='section'>").count).to eq 2
      end

      it '4 questions' do
        expect(html_returned.split("<span class='question'>").count).to eq 5  # includes the starting section without a q
      end
    end

    describe 'default wrapping class and join string' do

      let(:html_returned) { mock_controller.build_main_missing_flash(missing_qs, display_q_nums,
                                                                     wrapping_class: 'wclass', joiner: '?') }

      it 'wraps everything with a div and a custom CSS class' do
        expect(html_returned).to match(/<div class='wclass'>(.*)<\/div>$/)
      end

      it 'uses custom separator' do
        expect(html_returned.split('?').count).to eq 6
        expect(html_returned.split('<br />').count).to eq 1
      end

    end

  end


  describe '#flash_main_missing_title' do

    let(:html_returned) { mock_controller.flash_main_missing_title }


    it 'main title has span with class=title' do
      expect(html_returned.split('</span>').count).to eq 1
      expect(html_returned.split('</span>')[0]).to match /<span class='title'>(.*)/

    end
  end


  describe '#flash_section_of_missing' do

    let(:html_returned) {   question = QuestionMock.new
                            question.text = 'question text'

                            mock_controller.flash_section_of_missing(question)
    }


    it 'section title for the missing question, surrounded by a span' do

      expect(html_returned.split('</span>').count).to eq 1
      expect(html_returned.split('</span>')[0]).to match /<span class='section'>sectionTitle/

    end

  end


  describe '#flash_question_missing' do

    describe "html_string for a good Q and display_number '3' " do

      let(:html_returned) { question = QuestionMock.new
                            question.text = 'question text'

                            mock_controller.flash_question_missing(question, '5')
                          }


      it '3 spans' do
        expect(html_returned.split('</span>').count).to eq 3
      end

      it "span around the word used for 'question'" do
        expect(html_returned.split('</span>')[0].strip).to  match(/<span class='question-word'>([^<]*)/)
      end

      it "span around the question number" do
        expect(html_returned.split('</span>')[1].strip).to match(/<span class='number'>\(5\)/)
      end

      it "span around the question itself" do
        expect(html_returned.split('</span>')[2].strip).to match(/<span class='question'>question text/)
      end
    end

  end

end
