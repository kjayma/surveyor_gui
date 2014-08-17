class SurveyorGui::SurveySectionsController < ApplicationController
  layout 'surveyor_gui/surveyor_gui_blank'

  def new
    @title = "Add Survey Section"
    survey = Survey.find(params[:survey_id])
    prev_section = SurveySection.find(params[:prev_section_id])
    @last_survey_section = survey.survey_sections.last
    @survey_section = survey.survey_sections
                            .build(:title => 'New Section',
                                   :display_order => prev_section.display_order + 1,
                                   :modifiable => true)
  end

  def edit
    @title = "Edit Survey Section"
    @survey_section = SurveySection.find(params[:id])
  end

  def create
    survey = Survey.find(params[:survey_section][:survey_id])
    SurveySection.where(:survey_id => survey.id)
                 .where("display_order >= ?", params[:survey_section][:display_order])
                 .update_all("display_order = display_order+1")
    @survey_section = survey.survey_sections.build(survey_section_params)
    @survey_section.display_order = params[:survey_section][:display_order].to_i
    #@survey_section.questions.build(:text=>'New question',:pick=>'none',:display_order=>0,:display_type=>'default').answers.build(:text=>'string', :response_class=>'string', :display_order=>1, :template=>true)
    if @survey_section.save
      redirect_to :back
    else
      render :action => 'new', :layout => 'surveyor_gui/surveyor_gui_blank'
    end
  end

  def update
    @title = "Update Survey Section"
    @survey_section = SurveySection.find(params[:id])
    if @survey_section.update_attributes(survey_section_params)
      render :blank, :layout => 'surveyor_gui/surveyor_gui_blank'
    else
      render :action => 'edit', :layout => 'surveyor_gui/surveyor_gui_blank'
    end
  end

  def destroy
    @survey_section = SurveySection.find(params[:id])
    if !@survey_section.survey.template && @survey_section.survey.response_sets.count > 0
      render :text => "Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead."
      return false
    end
    if !@survey_section.modifiable
      render :text => "This section cannot be removed."
      return false
    end
    if !@survey_section.questions.map{|q| q.dependency_conditions}.flatten.blank?
      render :text => "The following questions have logic that depend on questions in this section: \n\n"+@survey_section.questions.map{|q| q.dependency_conditions.map{|d| " - "+d.dependency.question.text}}.flatten.join('\n')+"\n\nPlease delete logic before deleting this section.".html_safe
      return
    end
    @survey_section.destroy
    render :text => ""
  end

  def sort
    survey = Survey.find(params[:survey_id])
    satts = { :id => params[:survey_id], :survey_sections_attributes=>{} }
    sections = params[:survey_section]
    sections.each_with_index do |sid, index|
      satts[:survey_sections_attributes][index.to_s] = { :id => sid, :display_order => index }
    end
    puts satts
    survey.update_attributes!(satts)
    render :nothing => true
  end

  private
  def survey_section_params
    ::PermittedParams.new(params[:survey_section]).survey_section
  end

end
