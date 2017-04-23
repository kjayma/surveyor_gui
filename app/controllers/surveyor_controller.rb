module SurveyorControllerCustomMethods


  def self.included(base)
    base.send :layout, 'surveyor_gui/surveyor_modified'
  end


  def edit
    root = File.expand_path('../../', __FILE__)
    #place the surveyor_gui views ahead of the default surveyor view in order of preference
    #so we can load customized partials.

    # This will clobber the main application. BAD BAD BAD!
    prepend_view_path(root+'/views')

    # Instead, search for the surveyor gem path and just be sure that we are ahead of *that*.
    #  Thus the main application can still override views as needed.


    super
  end


  def update
    question_ids_for_dependencies = (params[:r] || []).map {|k, v| v["question_id"]}.compact.uniq
    saved = load_and_update_response_set_with_retries

    if saved && params[:finish] && !@response_set.mandatory_questions_complete?
      #did not complete mandatory fields
      ids, remove, question_ids, flashmsg = {}, {}, [], []
      flashmsg << I18n.t('surveyor_gui.update.complete_required')

      triggered_mandatory_missing = @response_set.triggered_mandatory_missing

      survey_section = ''
      question_number = {}
      last_question_of_previous_section = 0
      last_question_number = 0
      @response_set.survey.survey_sections.each do |ss|
        index = 0
        ss.questions.where('display_type!=?', 'label').each do |q|
          if q.triggered?(@response_set)
            question_number[q.id.to_s] = last_question_number = last_question_of_previous_section + index + 1
            index = index + 1
          end
        end
        last_question_of_previous_section = last_question_number
      end

      triggered_mandatory_missing.each do |m|
        if m.survey_section_id != survey_section
          survey_section = m.survey_section_id
          flashmsg << ""
          flashmsg << "&nbsp;&nbsp;" + m.survey_section.title
        end

        flashmsg << "&nbsp;&nbsp;&nbsp;&nbsp;#{t('activerecord.attributes.question.text')}&nbsp;" + question_number[m.id.to_s].to_s + ') '+ m.text
      end

      respond_to do |format|
        format.js do

          render :json => {"flashmsg" => flashmsg}
        end
        format.html do
          flash[:notice] = flashmsg.join('<br />')
          redirect_to surveyor.edit_my_survey_path(:anchor => anchor_from(params[:section]), :section => section_id_from(params))
        end
      end
      return


      #    elsif @response_set.survey.id.to_s == evaluation_institution.institution.vendor_value_analysis_questionnaire_id && saved && params[:finish]

    elsif saved && params[:finish]
      return redirect_with_message(surveyor_finish, :notice, t('surveyor.completed_survey'))
    end


    respond_to do |format|
      format.html do
        if @response_set.nil?
          return redirect_with_message(surveyor.available_surveys_path, :notice, t('surveyor.unable_to_find_your_responses'))
        else
          flash[:notice] = t('surveyor.unable_to_update_survey') unless saved
          redirect_to surveyor.edit_my_survey_path(:anchor => anchor_from(params[:section]), :section => section_id_from(params))
        end
      end
      format.js do
        if @response_set
          render :json => @response_set.reload.all_dependencies(question_ids_for_dependencies)
        else
          render :text => "#{t('surveyor_gui.update.no_response_set')} #{params[:response_set_code]}",
                 :status => 404
        end
      end
    end

  end
end


class SurveyorController < ApplicationController
  include Surveyor::SurveyorControllerMethods
  include SurveyorControllerCustomMethods
end
