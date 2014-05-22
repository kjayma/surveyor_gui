# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Question do
  let(:question){ FactoryGirl.create(:question) }

  context "without answers" do
    let(:answers_collection){"blue\nred\ngreen"}

    it "builds answers from the answers_collection field" do
      question.answers_collection = answers_collection
      question.save
      expect(question.answers.count).to eq 3
      expect(question.answers.to_s).to match /blue.*red.*green/
    end
  end

  context "with answers" do
    let(:answer_1){ FactoryGirl.create(:answer, :question => question, :display_order => 3, :text => "blue")}
    let(:answer_2){ FactoryGirl.create(:answer, :question => question, :display_order => 1, :text => "red")}
    let(:answer_3){ FactoryGirl.create(:answer, :question => question, :display_order => 2, :text => "green")}
    before do
      [answer_1, answer_2, answer_3].each{|a| question.answers << a }
    end

    it "builds an answers_collection field" do
      expect(question.answers_collection).to match /blue\nred\ngreen/
    end
  end

end
