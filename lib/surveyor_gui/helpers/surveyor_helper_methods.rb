module SurveyorGui
  module Helpers
    module SurveyorGuiHelperMethods

      # Responses
      def response_for(response_set, question, answer = nil, response_group = nil, column_id = nil)
        return nil unless response_set && question && question.id
        result = response_set.responses.detect{|r| 
          (r.question_id == question.id) && 
          (answer.blank? ? true : r.answer_id == answer.id) && 
          (r.response_group.blank? ? true : r.response_group.to_i == response_group.to_i) && 
          (r.column_id.blank? ? true : r.column_id == column_id.to_i)}
        result.blank? ? response_set.responses.build(
          question_id: question.id, 
          response_group: response_group, 
          column_id: column_id) : result
      end


      # HTML to display for a surveys's preamble
      def survey_preamble_html(survey)

        s_preamble_id = 'preamble'
        s_preamble_class = 'survey_preamble'

        pre_post_survey_html_text( survey, :preamble, s_preamble_id, s_preamble_class )

      end


      # HTML to display for a survey's postscript
      def survey_postscript_html(survey)

        s_postscript_class = 'question_postscript'
        s_postscript_id = 'postscript'

        pre_post_survey_html_text( survey, :postscript, s_postscript_id, s_postscript_class )

      end


      # HTML for the survey text that should be displayed as html_safe
      def pre_post_survey_html_text(s, text_method, id_name, text_class_name)

        html_div_html_safe(s, text_method, id_name, text_class_name)

      end


      # HTML to display for a question's preamble
      def q_preamble_html(question, response_set)

        q_preamble_id = 'preamble'
        q_preamble_class = 'question_preamble'

        pre_post_q_html_text(question, :preamble, q_preamble_id, q_preamble_class,  question.css_class(response_set))


      end


      # HTML to display for a question's postscript
      def q_postscript_html(question, response_set)

        q_postscript_class = 'question_postscript'
        q_postscript_id = 'postscript'

        pre_post_q_html_text(question, :postscript, q_postscript_id, q_postscript_class,  question.css_class(response_set))

      end


      # HTML for question text that should be displayed as html_safe
      def pre_post_q_html_text(q, text_method, id_name, text_class_name, q_classes)

        html_div_html_safe(q, text_method, "#{q.id}-#{id_name}", "#{text_class_name} #{q_classes}")

      end


      #--------
      #  Answers


      # HTML for a Bootstrap tooltop
      def tool_tip_from_help(answer)
        "data-toggle='tooltip' title='#{answer.help_text_for(nil, I18n.locale) unless g && g.display_type == "grid"}'"
      end



      # HTML for text that should be displayed as html_safe, surrounded by a div with the id and class
      #
      # if the model has this method defined (ex: if 'preamble' is defined for the Question model),
      #   and there is some content for this thing (size > 0),
      #     return a div with id and classes set for the content
      # else return an empty string

      def html_div_html_safe(model, method, id, css_class)

        if ( model.respond_to? method) && (model.send(method).present? )
          content_tag(:div, model.send(method).html_safe, id: "#{id}", class: "#{css_class}")
        else
          ''
        end

      end


    end
  end
end
