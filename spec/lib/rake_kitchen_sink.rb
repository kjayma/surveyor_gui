require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rake'

describe Surveyor::Parser do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.add_import "#{gem_path('surveyor')}/lib/tasks/surveyor_tasks.rake"
    Rake.application.load_imports
    Rake::Task.define_task(:environment)
  end
  it "should return properly parse the kitchen sink survey" do
    ENV["FILE"]="surveys/kitchen_sink_survey.rb"
    @rake["surveyor"].invoke

    Survey.count.should == 1
    SurveySection.count.should == 2
    Question.count.should == 51
    Answer.count.should == 252
    Dependency.count.should == 8
    DependencyCondition.count.should == 12
    QuestionGroup.count.should == 6

    Survey.all.map(&:destroy)
  end
  it "should return properly parse a UTF8 survey" do
    pending "failing - not clear why - await update of surveyor"
    ENV["FILE"]="../spec/fixtures/chinese_survey.rb"
    @rake["surveyor"].invoke

    Survey.count.should == 1
    SurveySection.count.should == 1
    Question.count.should == 3
    Answer.count.should == 15
    Dependency.count.should == 0
    DependencyCondition.count.should == 0
    QuestionGroup.count.should == 1

    Survey.all.map(&:destroy)
  end

end
