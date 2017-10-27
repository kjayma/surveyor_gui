class SurveyorGui::SurveyController < ApplicationController
  def show
    @title = I18n.t('surveyor_gui.surveys.show.user_will_see')
    @survey = Survey.find(params[:survey_id])
    user_id = defined?(current_user) && current_user ? current_user.id : 1 
    ResponseSet.where('survey_id = ? and test_data = ? and user_id = ?',params[:survey_id],true, user_id).each {|r| r.destroy}
    @response_set = ResponseSet.create(:survey => @survey, :user_id => user_id, :test_data => true)
    if (@survey)
      #flash[:notice] = t('surveyor.survey_started_success')
      redirect_to surveyor.edit_my_survey_path @survey.access_code, @response_set.access_code
    else
      flash[:notice] =  I18n.t('surveyor_gui.not_found', item: I18n.t('surveyor_gui.survey') )
      redirect :back
    end
  end
end
