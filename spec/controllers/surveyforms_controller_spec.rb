require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveyformsController do
  include Surveyor::Engine.routes.url_helpers
#  before do
#    @routes = Surveyor::Engine.routes
#  end

  let!(:survey) { Factory(:survey, :title => "Alphabet", :access_code => "alpha", :survey_version => 0)}
  let!(:survey_beta) { Factory(:survey, :title => "Alphabet", :access_code => "alpha", :survey_version => 1)}
  let!(:response_set) { Factory(:response_set, :survey => survey, :access_code => "pdq")}
  let!(:response_set_beta) { Factory(:response_set, :survey => survey_beta, :access_code => "rst")}
  before { ResponseSet.stub(:create).and_return(response_set) }

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

  context "#edit" do
    def do_get(params = {})
      survey.sections = [Factory(:survey_section, :survey => survey)]
      get :edit, {:survey_code => "alpha", :response_set_code => "pdq"}.merge(params)
    end
    it "renders edit" do
      do_get
      response.should be_success
      response.should render_template('edit')
    end
  end
  end

end
