require 'spec_helper'

module CapybaraHelper
  Capybara::Session::DSL_METHODS.each do |method|
    define_method method do |*args, &block|
      Capybara.string(response).send method, *args, &block
    end
  end
end

describe "surveyforms/edit.html.erb" do
  include CapybaraHelper
  let(:surveyform){ FactoryGirl.create(:surveyform) }
  let(:ss){ FactoryGirl.create(:survey_section, :surveyform => surveyform, :title => "Rooms", :display_order => 0)}
  let(:question){ FactoryGirl.create(:question, :survey_section => ss) }  
  let(:question1){ FactoryGirl.create(
    :question, 
    survey_section: ss, 
    question_type: "Multiple Choice (only one answer)",
    answers_textbox: "Standard\nDouble\nDeluxe"
   ) }  
   
  let(:qg){FactoryGirl.create(:question_group, text: 'Rate the meals.') }
  let(:question2){ FactoryGirl.create(
    :question, 
    text: 'Breakfast',
    survey_section: ss, 
    question_group: qg,
    question_type: "Multiple Choice (only one answer)",
    answers_textbox: "Good\nBad\nUgly"
   ) }    
   let(:question3){ FactoryGirl.create(
    :question, 
    text: 'Lunch',
    survey_section: ss, 
    question_group: qg,
    question_type: "Multiple Choice (only one answer)",
    answers_textbox: "Good\nBad\nUgly"
   ) }   
   let(:question4){ FactoryGirl.create(
    :question, 
    text: 'Dinner',
    survey_section: ss, 
    question_group: qg,
    question_type: "Multiple Choice (only one answer)",
    answers_textbox: "Good\nBad\nUgly"
   ) } 
  let(:question5){ FactoryGirl.create(:question, :survey_section => ss, text: "What brand of ketchup do they use?") }    
  
  
  before do
    surveyform.save
    surveyform.reload
    ss.reload
    question.reload
    question1.reload
    question2.reload
    question3.reload
    question4.reload
    qg.reload
    assign(:surveyform, surveyform)
    assign(:question_no, 0)
  end    
  
  it "renders a form" do
    render
    expect(response).to have_selector("form")
  end

  it "shows text questions" do
    render
    expect(response).to have_selector('input[type="text"]')
  end
  
  it "shows multiple choice questions" do
    render
    expect(response).to have_selector("input[type='radio'][value='Standard']")
    expect(response).to have_selector("input[type='radio'][value='Double']")
    expect(response).to have_selector("input[type='radio'][value='Deluxe']")
  end
  
  it "shows grid questions" do
    render
    expect(response).to match(/2\) Rate the meals\..*Good.*Bad.*Ugly.*(?<!\))\sBreakfast.*(?<!\))\sLunch.*(?<!\))\sDinner.*/)
  end
  
  it "maintains correct question numbering after grid question" do
    render
    expect(response).to match(/"3\) What brand of ketchup do they use?"/)
  end
end
