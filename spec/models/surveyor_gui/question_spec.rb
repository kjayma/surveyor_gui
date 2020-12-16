# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Question do
  let(:question){ FactoryBot.create(:question) }
  let(:question2){ FactoryBot.create(:question, question_type_id: "pick_one")}

  def build_answers_from_answers_textbox
      question2.answers_textbox = "blue\nred\ngreen"
      question2.save
      question2.reload
      expect(question2.answers.count).to eq 3
      expect(question2.answers.where('text=?','blue').first.display_order).to eq 0
      expect(question2.answers.where('text=?','red').first.display_order).to eq 1
      expect(question2.answers.where('text=?','green').first.display_order).to eq 2
  end

  context "without answers" do

    it "builds answers from the answers_textbox field" do
      build_answers_from_answers_textbox
    end

  end

  context "with answers" do
    let(:answer_1){ FactoryBot.create(:answer, :question => question2, :display_order => 3, response_class: "answer", :text => "blue")}
    let(:answer_2){ FactoryBot.create(:answer, :question => question2, :display_order => 1, response_class: "answer", :text => "red")}
    let(:answer_3){ FactoryBot.create(:answer, :question => question2, :display_order => 2, response_class: "answer", :text => "green")}
    before do
      [answer_1, answer_2, answer_3].each{|a| question2.answers << a }
    end

    it "builds an answers_textbox field sorted by display_order" do
      expect(question2.answers_textbox).to match /red\ngreen\nblue/
    end

    it "does not duplicate answers with lines from answers_textbox" do
      build_answers_from_answers_textbox
    end

    context "when deleting" do
      before do
        question2.answers_textbox = "blue\ngreen"
        question2.save
        question2.reload
      end

      it "deletes answers that are not in answers_textbox" do
        expect(question2.answers.to_s).not_to match "red"
      end

      it "maintains the correct display order after deleting an answer" do
        expect(question2.answers.where('text=?','blue').first.display_order).to eq 0
        expect(question2.answers.where('text=?','green').first.display_order).to eq 1
      end
    end
  end

end
