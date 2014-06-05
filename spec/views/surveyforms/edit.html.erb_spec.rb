require 'spec_helper'

module CapybaraHelper
  Capybara::Session::DSL_METHODS.each do |method|
    define_method method do |*args, &block|
      Capybara.string(response).send method, *args, &block
    end
  end
end
RSpec.configure do |config|
  config.order =  :default
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
  let(:qg2){FactoryGirl.create(:question_group, display_type: 'grid', text: 'Pick your favorite sport') }
  let(:c1) {FactoryGirl.create(:column, question_group_id: qg2.id, text: "Spring", answers_textbox: "Football\nBaseball\nHockey\nSoccer\nBasketball" )}
  let(:c2) {FactoryGirl.create(:column, question_group_id: qg2.id, text: "Summer", answers_textbox: "Football\nBaseball\nHockey\nSoccer\nBasketball" )}
  let(:c3) {FactoryGirl.create(:column, question_group_id: qg2.id, text: "Fall", answers_textbox: "Football\nBaseball\nHockey\nSoccer\nBasketball")}
  let(:c4) {FactoryGirl.create(:column, question_group_id: qg2.id, text: "Winter", answers_textbox: "Football\nBaseball\nHockey\nSoccer\nBasketball")}
  let(:question2){ FactoryGirl.create(
    :question, 
    text: 'Rate the meals.',
    survey_section: ss, 
    question_group: nil,
    question_type_id: "grid_one",
    grid_columns_textbox: "Good\nBad\nUgly",
    grid_rows_textbox: "Breakfast\nLunch\nDinner"
   ) }    

  let(:question5){ FactoryGirl.create(:question, :survey_section => ss, text: "What brand of ketchup do they use?") }    
  let(:answer1){FactoryGirl.create(:answer, :question => question5)}
  let(:question6) { FactoryGirl.create(
    :question, 
    survey_section: ss, 
    question_group: qg2,
    question_type_id: "grid_dropdown",
    grid_rows_textbox: "TV\nArena",
    text: "Pick your favorite sport:"
  ) }    
  
  before do
    surveyform.save
    surveyform.reload
    ss.reload
    question.reload
    qg.reload
    qg2.reload
    c1.reload
    c2.reload
    c3.reload
    c4.reload
    question1.reload
    question2.reload
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

  it "shows grid dropdowns" do
    render    
    expect(response).to match(/4\) Pick your favorite sport.*Spring.*Summer.*Fall.*Winter.*(?<!\d\)\s)TV.*(?<!\d\)\s)Arena/m)
  end
  
  it "maintains correct question numbering after grid questions" do
    render
    expect(response).to match(/5\) What brand of ketchup do they use?/)
  end
end
