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
end
