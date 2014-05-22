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
  def message
    mock_model("Question",
      :text =>'who are you?',
      :question_type => 'Multiple Choice'
      ).as_new_record.as_null_object
  end
  helper_method :message

  describe "renders a form to create the message" do
    let (:form) {find('form')}
    it "renders a form" do
      render
      expect(response).to have_selector("form")
    end
    it "will post a new message on submit" do
      render
      expect(form[:action]).to eql(messages_path)
      expect(form[:method]).to eql('post')
    end
    it "has a save button" do
      render
      expect(form).to have_selector("input[type=submit]")
    end
    it "renders a text field for the message title" do
      render
      expect(form).to have_field(
        "message[title]",
        :type => 'text',
        :with => 'the title')
    end
    it "renders a text area for the message text" do
      render
      expect(rendered).to have_field(
        'message[text]',
        :type => 'textarea',
        :with => 'the message')
    end
  end
end
