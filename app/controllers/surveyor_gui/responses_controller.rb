class SurveyorGui::ResponsesController < ApplicationController

  include ReportPreviewWrapper
  # ReportPreviewWrapper wraps preview in a database transaction so test data is not permanently saved.
  around_action :wrap_in_transaction, only: :preview
  layout 'surveyor_gui/surveyor_gui_default'


  def index
    @title         = I18n.t('surveyor_gui.responses.index.title')
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
      flash[:notice] = I18n.t('surveyor_gui.not_found', item: I18n.t('surveyor_gui.survey') )
      redirect_to :back
    end

    @title        = I18n.t('surveyor_gui.responses.preview.title', responses_title: response_set_title)

    render :show
  end


  def show
    @response_set  = ResponseSet.find(params[:id])

    @title         = I18n.t('surveyor_gui.responses.show.title', responses_title: response_set_title)

    @survey        = @response_set.survey
    @responses     = @response_set.responses
    @response_sets = [@response_set]

    if (!@response_set)
      flash[:error] = I18n.t('surveyor_gui.not_found', item: I18n.t('surveyor_gui.response') )
      redirect_to :back
    elsif (!@survey)
      flash[:error] =  I18n.t('surveyor_gui.not_found', item: I18n.t('surveyor_gui.survey') )
      redirect_to :back
    end

  end

  private

  def response_set_title
    I18n.t('surveyor_gui.responses.responses_for_access_code', response_set_access_code: @response_set.access_code )
  end

end
