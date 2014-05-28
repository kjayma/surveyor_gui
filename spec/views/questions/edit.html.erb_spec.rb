require 'spec_helper'

module CapybaraHelper
  Capybara::Session::DSL_METHODS.each do |method|
    define_method method do |*args, &block|
      Capybara.string(response).send method, *args, &block
    end
  end
end

describe "questions/edit.html.erb" do
  include CapybaraHelper

  let(:question){ FactoryGirl.create(:question) }
  let(:question2){ FactoryGirl.create(:question, :question_type_id => "pick_one") }
  let(:form){find('form')}
   
  before do
    assign(:question, question)
  end    
  
  it "renders a form" do
    render
    expect(response).to have_selector("form")
  end

  it "will post a new question on submit" do
    render
    expect(form[:action]).to eql(question_path question)
    expect(form[:method]).to eql('post')
  end
  
  it "has a save button" do
    render
    expect(form).to have_selector("input[type=submit]")
  end
    
  context "It has a multiple choice field" do
    let (:form) {find('form')}
    let(:answer_1){ FactoryGirl.create(:answer, :question => question2, :display_order => 3, :text => "blue")}
    let(:answer_2){ FactoryGirl.create(:answer, :question => question2, :display_order => 1, :text => "red")}    
    let(:answer_3){ FactoryGirl.create(:answer, :question => question2, :display_order => 2, :text => "green")}
   
    before do
      [answer_1, answer_2, answer_3].each{|a| question2.answers << a } 
      assign(:question, question2)    
    end
    
    #won't work for now because of js
    #it "renders an answer_collection for the answers" do
    #  render
    #  puts rendered
    #  expect(rendered).to have_field(
    #    'question[answers_textbox]',
    #    :type => 'textarea',
    #    :with => "red\ngreen\nblue")
    #end
  end


#    it "renders a text field for the message title" do
#      render
#      expect(form).to have_field(
#        "message[title]",
#        :type => 'text',
#        :with => 'the title')
#    end
#    it "renders a text area for the message text" do
#      render

#    end
#  end
end
