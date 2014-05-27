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
  let(:answer){ FactoryGirl.create(:answer, :question => question)}
  let(:question1){ FactoryGirl.create(
    :question, 
    survey_section: ss, 
    text: 'What rooms do you prefer?',
    question_type_id: "pick_one",
    answers_textbox: "Standard\nDouble\nDeluxe"
   ) }  
   
  let(:qg) {FactoryGirl.create(:question_group, display_type: 'grid', text: 'Rate the meals.') }
  let(:qg2){FactoryGirl.create(:question_group, display_type: 'grid', text: 'Rate the snacks.') }
  let(:question2){ FactoryGirl.create(
    :question, 
    text: 'Breakfast',
    survey_section: ss, 
    question_group: qg,
    question_type_id: "pick_one",
    answers_textbox: "Good\nBad\nUgly"
   ) }    
   let(:question3){ FactoryGirl.create(
    :question, 
    text: 'Lunch',
    survey_section: ss, 
    question_group: qg,
    question_type_id: "pick_one",
    answers_textbox: "Good\nBad\nUgly"
   ) }   
   let(:question4){ FactoryGirl.create(
    :question, 
    text: 'Dinner',
    survey_section: ss, 
    question_group: qg,
    question_type_id: "pick_one",
    answers_textbox: "Good\nBad\nUgly"
   ) } 
  let(:question5){ FactoryGirl.create(:question, :survey_section => ss, text: "What brand of ketchup do they use?") }    
  let(:answer1){FactoryGirl.create(:answer, :question => question5)}
  let(:question6) { FactoryGirl.create(
    :question, 
    survey_section: ss, 
    question_group: qg2,
    question_type_id: "grid_one",
    grid_columns_textbox: "Good\nBad\nUgly",
    grid_rows_textbox: "Brunch\nLinner\nLate Night Snack",
    text: "Brunch"
  ) }    
  
  before do
    surveyform.save
    surveyform.reload
    ss.reload
    question.reload
    qg.reload
    qg2.reload
    question1.reload
    question2.reload
    question3.reload
    question4.reload
    question5.reload
    question6.reload
    answer.reload
    answer1.reload
    assign(:surveyform, surveyform)
    assign(:question_no, 0)
  end    
  
  it "renders a form" do
    render
    expect(response).to have_selector("form")
  end

  it "shows text questions" do
    render
    expect(response).to match(/1\) What is your favorite color?/)
  end
  
  it "shows multiple choice questions" do
    render
    expect(response).to have_selector("input[type='radio'][value='Standard']")
    expect(response).to have_selector("input[type='radio'][value='Double']")
    expect(response).to have_selector("input[type='radio'][value='Deluxe']")
  end
  
  it "shows grid questions" do
    render
    expect(response).to match (/Rate the meals/)
    expect(response).to match(/3\) Rate the meals\..*Good.*Bad.*Ugly.*(?<!\d\)\s)Breakfast.*(?<!\d\)\s)Lunch.*(?<!\d\)\s)Dinner.*/m)
  end
  
  it "shows grid questions generated from textboxes" do
    render
    expect(response).to match (/Rate the meals/)
    expect(response).to match(/5\) Rate the snacks\..*Good.*Bad.*Ugly.*(?<!\d\)\s)Brunch.*(?<!\d\)\s)Linner.*(?<!\d\)\s)Late Night Snack.*/m)
  end
  
  it "maintains correct question numbering after grid question" do
    render
    expect(response).to match(/4\) What brand of ketchup do they use?/)
  end
end
