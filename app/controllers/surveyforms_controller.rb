class SurveyformsController < ApplicationController
  def index
    if params[:template]=='false'
      template=false
    elsif params[:tempate]=='true'
      template=true
		else
			template=false
    end
    @title = "Modify " + (template ? "Templates" : "Surveys")
	 	@surveyforms = Surveyform.where('template = ?',template).search(params[:search]).order(:title).paginate(:page => params[:page])
  end

  def edit
    @surveyform = Surveyform.where(:id=>params[:id]).includes(:survey_sections).first
    @survey_locked=false
    #unfortunately, request.referrer does not seem to capture parameters. Need to add explicitly.
    #don't edit the format of a non template survey that has responses. could cause unpredictable results
    @surveyform.response_sets.where('test_data=?',true).map{|r| r.destroy}
    if !@surveyform.template && @surveyform.response_sets.count>0
      @survey_locked=true
      flash.now[:error] = "Reponses have already been collected for this survey, therefore any modifications you make will not be saved."
    end
    @title = "Edit "+ (@surveyform.template ? 'Template' : 'Survey')
    @surveyform.survey_sections.build if @surveyform.survey_sections.blank?
    @question_no = 0
    @url = "update"
  end

end
