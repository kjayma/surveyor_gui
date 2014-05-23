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
  
  before do
    surveyform.save
    surveyform.reload
    ss.reload
    question.reload
    question1.reload
    assign(:surveyform, surveyform)
    assign(:question_no, 0)
  end    
  
  it "renders a form" do
    render
    expect(response).to have_selector("form")
  end

  it "shows text questions" do
    render
    expect(response).to have_selector("input[type='text']")
  end
  
  it "shows multiple choice questions" do
    render
    expect(response).to have_selector("input[type='radio']")
  end
end
