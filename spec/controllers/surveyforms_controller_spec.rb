require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveyformsController do
  include Surveyor::Engine.routes.url_helpers
#  before do
#    @routes = Surveyor::Engine.routes
#  end

  let!(:survey) { FactoryGirl.create(:survey, :id=> 1, :title => "Alphabet", :access_code => "alpha", :survey_version => 0)}
  let!(:survey_beta) { FactoryGirl.create(:survey, :id => 2, :title => "Alphabet", :access_code => "alpha", :survey_version => 1)}
  let!(:survey_with_no_responses) {FactoryGirl.create(:survey)}
  let!(:survey_with_responses) {FactoryGirl.create(:survey)}
  let!(:template) {FactoryGirl.create(:template)}
  let!(:surveyform) {FactoryGirl.create(:surveyform)}
  let!(:response_set) { FactoryGirl.create(:survey_sections, :survey => survey_with_responses)}
  let!(:response_set) { FactoryGirl.create(:response_set, :survey => survey_with_responses, :access_code => "pdq")}
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
      get :index, params
    end

    context "parameters call for surveys" do

      it "set the title to 'modify surveys'" do
        do_get()
        assigns(:title).should eq("Modify Surveys")
      end

      it "should not populate an array of templates" do
        do_get()
        expect(assigns(:surveyforms)).not_to eq([template])
      end

      it "should populate an array of surveys" do
        do_get()
        expect(assigns(:surveyforms)).to include(surveyform)
      end

      it "shows the surveys" do
        do_get()
        expect(response).to render_template('index')
      end
    end

    context "parameters call for survey templates" do

      it "set the title to 'modify templates'" do
        do_get(:template=>"true")
        assigns(:title).should eq("Modify Templates")
      end

      it "should populate an array of templates" do
        do_get(params={:template=>"true"})
        expect(assigns(:surveyforms)).to eq([template])
      end

      it "should not populate an array of surveys" do
        do_get(params={:template=>"true"})
        expect(assigns(:surveyforms)).not_to eq([surveyform])
      end

      it "shows the survey templates" do
        do_get(:template=>"true")
        expect(response).to render_template('index')
      end
    end
  end

  context "#new" do
    def do_get
      get :new
    end

    it "renders new" do
      do_get
      expect(response).to be_success
      expect(response).to render_template('new')
    end

    it "populates an empty survey" do
      do_get
      expect(assigns(:surveyform).id).to eq(nil)
    end
  end

  context "#create" do

    def do_post(params = {})
      post :create, :surveyform=>params
    end

    context "it saves successfully" do

      it "returns to the edit page" do
        do_post(:title=>'New surv')
        expect(response).to redirect_to(edit_surveyform_url(assigns(:surveyform).id))
      end

      it "resets question_no to 0" do
        do_post(:title=>'New surv')
        expect(assigns(:question_no)).to eq(0)
      end

    end

    context "it fails to save" do

      it "renders new" do
        do_post()
        expect(response).to render_template('new')
      end

    end
  end

  context "#edit" do

    context "the survey has no responses" do

      def do_get(params = {})
        get :edit, {:id => 1}.merge(params)
      end

      it "renders edit" do
        do_get
        expect(response).to be_success
        expect(response).to render_template('edit')
      end
    end

    context "the survey has responses" do

      def do_get(params = {})
        get :edit, {:id => 1}.merge(params)
      end

      it "still lets you see the edit page" do
        do_get
        expect(response).to be_success
        expect(response).to render_template('edit')
      end
      it "warns that responses have been collected" do
        expect(flash[:error]) =~ /been collected/i
      end
    end
  end

  context "#update" do

    context "it saves successfully" do

      def do_put(params = {})
        put :update, params
      end

      it "redirects to index" do
        do_put(:id=>1,:surveyform=>{:id=>1})
        expect(response).to redirect_to(surveyforms_url)
      end

    end

    context "it fails to save" do

      def do_put(params = {})
        put :update, params
      end

      it "renders edit" do
        do_put(:id=>1,:surveyform=>{:id=>1,:title=>''})
        expect(response).to render_template('edit')
      end

      it "resets question_no to 0" do
        do_put(:id=>1,:surveyform=>{:id=>1,:title=>''})
        expect(assigns(:question_no)).to eq(0)
      end

    end

  end


  context "#show" do
    def do_get
      get :show, {:id => 1}
    end

    it "shows survey" do
      do_get
      expect(response).to be_success
      expect(response).to render_template('show')
    end
  end

  context "#destroy" do

    context "responses were submitted" do
      def do_delete
        delete :destroy, :id => survey_with_no_responses
      end

      it "successfully destroys the survey" do
        do_delete
        expect(response).to redirect_to(surveyforms_url)
        expect(Survey.exists?(survey_with_no_responses.id)).to be_false
      end
    end

    context "no responses were submitted" do
      def do_delete
        delete :destroy, :id => survey_with_responses
      end

      it "fails to delete the survey" do
        do_delete
        expect(response).to redirect_to(surveyforms_url)
        expect(Survey.exists?(survey_with_responses.id)).to be_true
      end
    end
  end

  context "#insert_survey_section" do
    def do_get(params = {})
      survey.sections = [FactoryGirl.create(:survey_section, :survey => survey)]
      get :insert_survey_section,{:id => 1}.merge(params)
    end
    it "inserts a survey section" do
      do_get
      expect(response).to be_success
      expect(response).to render_template('_survey_section_fields')
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
      expect(response).to be_success
      expect(response).to render_template('new')
    end
  end
end
