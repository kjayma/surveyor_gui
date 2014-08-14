class SurveyorGui::ResponsesController < ApplicationController

  # ReportPreviewWrapper wraps preview in a database transaction so test data is not permanently saved.
  around_action :report_preview_wrapper, only: :preview
  layout 'surveyor_gui_default'

  def index
    @title = "Survey Responses"
    @response_sets = Survey.find_by_id(params[:id]).response_sets
  end
 
  def preview 
    user_id = defined?(current_user) ? current_user.id : 1 
    @title = "Show Response"
    @survey = Survey.find(params[:survey_id])
    @response_set = ResponseSet.create(:survey => @survey, :user_id => user_id, :test_data => true)
    ReportResponseGenerator.new(@survey).generate_1_result_set(@response_set)
    @responses = @response_set.responses
    if (!@survey)
      flash[:notice] = "Survey/Questionnnaire not found."
      redirect_to :back
    end
    render :show    
  end

  def show
    @title = "Show Response"
    @response_set = ResponseSet.find(params[:id])
    @survey = @response_set.survey
    @responses = @response_set.responses
    if (!@response_set)
      flash[:error] = "Response not found"
      redirect_to :back
    elsif (!@survey)
      flash[:error] = "Survey/Questionnnaire not found."
      redirect_to :back
    end
  end

  private

  def report_preview_wrapper
    ReportPreviewWrapper.new
  end
end
