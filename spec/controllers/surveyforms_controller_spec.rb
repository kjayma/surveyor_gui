require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveyformsController do
  include Surveyor::Engine.routes.url_helpers
#  before do
#    @routes = Surveyor::Engine.routes
#  end

  let!(:survey) { FactoryGirl.create(:survey, :id=> 1, :title => "Alphabet", :access_code => "alpha", :survey_version => 0)}
  let!(:survey_beta) { FactoryGirl.create(:survey, :id => 2, :title => "Alphabet", :access_code => "alpha", :survey_version => 1)}
  #let!(:response_set) { FactoryGirl.create(:response_set, :survey => survey, :access_code => "pdq")}
  #let!(:response_set_beta) { Factory(:response_set, :survey => survey_beta, :access_code => "rst")}
  #before { ResponseSet.stub(:create).and_return(response_set) }

  # match '/', :to => 'surveyor#new', :as => 'available_surveys', :via => :get
  # match '/:survey_code', :to => 'surveyor#create', :as => 'take_survey', :via => :post
  # match '/:survey_code', :to => 'surveyor#export', :as => 'export_survey', :via => :get
  # match '/:survey_code/:response_set_code', :to => 'surveyor#show', :as => 'view_my_survey', :via => :get
  # match '/:survey_code/:response_set_code/take', :to => 'surveyor#edit', :as => 'edit_my_survey', :via => :get
  # match '/:survey_code/:response_set_code', :to => 'surveyor#update', :as => 'update_my_survey', :via => :put

  context "#index" do
 		def do_get(params = {})
      get :index
    end
    it "shows the surveys" do
      do_get
      response.should be_success
      response.should render_template('index')
    end
  end

  context "new" do
    def do_get
      get :new
    end
    it "renders new" do
      do_get
      response.should be_success
      response.should render_template('new')
    end
  end

  context "#edit" do
    def do_get(params = {})
      survey.sections = [FactoryGirl.create(:survey_section, :survey => survey)]
      get :edit, {:id => 1}.merge(params)
    end
    it "renders edit" do
      do_get
      response.should be_success
      response.should render_template('edit')
    end
  end

  context "#insert_survey_section" do
    def do_get(params = {})
      survey.sections = [FactoryGirl.create(:survey_section, :survey => survey)]
      get :insert_survey_section,{:id => 1}.merge(params)
    end
    it "inserts a survey section" do
      do_get
      response.should be_success
      response.should render_template('_survey_section_fields')
    end
  end

  context "#insert_new_question" do
    def do_get(params = {})
      survey.sections = [FactoryGirl.create(:survey_section, :survey => survey)]
      survey.sections.first.questions = [FactoryGirl.create(:question, :survey_section => survey.sections.first)]
      get :insert_new_question,{:id => 1, :question_id => 1}.merge(params)
    end
    it "inserts a question" do
      do_get
      response.should be_success
      response.should render_template('new')
    end
  end
end
