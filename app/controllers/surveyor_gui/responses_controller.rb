class SurveyorGui::ResponsesController < ApplicationController

  include ReportPreviewWrapper
  # ReportPreviewWrapper wraps preview in a database transaction so test data is not permanently saved.
  around_action :wrap_in_transaction, only: :preview
  layout 'surveyor_gui/surveyor_gui_default'


  def index
    @title         = "Survey Responses"  # TODO i18n
    @response_sets = Survey.find_by_id(params[:id]).response_sets
  end


  def preview

    user_id       = defined?(current_user) && current_user ? current_user.id : nil

    @survey       = Survey.find(params[:survey_id])

    @response_set = ResponseSet.create(:survey => @survey, :user_id => user_id, :test_data => true)
    ReportResponseGenerator.new(@survey).generate_1_result_set(@response_set)

    @responses     = @response_set.responses
    @response_sets = [@response_set]

    if (!@survey)
      flash[:notice] = "Survey/Questionnnaire not found."
      redirect_to :back
    end

    @title        = "Previewing  #{response_set_title}"

    render :show
  end


  def show
    @response_set  = ResponseSet.find(params[:id])

    @title         = "Showing #{response_set_title}"  # TODO i18n

    @survey        = @response_set.survey
    @responses     = @response_set.responses
    @response_sets = [@response_set]

    if (!@response_set)
      flash[:error] = "Response not found"
      redirect_to :back
    elsif (!@survey)
      flash[:error] = "Survey/Questionnnaire not found."
      redirect_to :back
    end

  end

  private

  def response_set_title
    "Responses for response set access_code: #{@response_set.access_code}"  # TODO i18n
  end

end
