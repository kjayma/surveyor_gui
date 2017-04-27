# Build flash messages when questions are missed that shouldn't have been
#  This mixin will make it easier for these methods to be overridden by
#  the main app or other gems. ONCE THE SILLY hardcoded reordering of this (e.g. in surveyor_controller.rb #edit)
#  is UNDONE.

module SurveyorGui

  module MissingInfoFlashBuilder


    # html for each part of the flash message that is needed when questions
    # are not answered.
    # This will return a string that have been put together using .join and the
    # separator passed in.
    #  This method is here so that it can be easily overridden by the main app,
    #  and it is broken down into discrete pieces so that you can easily
    #  override just the parts you need to behave differently.
    #
    # @param missing_questions - a list of questions that must be answered, but were missed
    # @param displayed_q_numbers - this can be expensive to figure out, so we are given this information
    #       so that we can use it in constructing the message for a question
    #
    def build_main_missing_flash(missing_questions, displayed_q_numbers, joiner: '<br/>', wrapping_class: 'surveyor-missing-qs')

      html_strs = []
      html_strs << "<div class='#{wrapping_class}'>" + flash_main_missing_title

      section_id_with_missing_q = ''

      missing_questions.each do | q |

       # if q.survey_section_id != section_id_with_missing_q
       #   section_id_with_missing_q = q.survey_section_id # once we've noted the section, we can ignore it
       #   html_strs << flash_section_of_missing(q)
       # end

        html_strs << flash_question_missing(q, displayed_q_numbers[q.id.to_s])

      end

      html_strs[html_strs.count-1] = html_strs[html_strs.count-1] + '</div>'
      html_strs.join(joiner)
    end


    def flash_main_missing_title
      "<span class='title'>" + I18n.t('surveyor_gui.update.complete_required') + "</span>"
    end


    # HTML to display in flash about questions missing in this section
    def flash_section_of_missing(missing_q)
      html_str = "<span class='section'>" + missing_q.survey_section.title + "</span>"
    end


    # HTML to display in flash about a specific missing question
    def flash_question_missing(q, display_number)

      html_str = "<span class='question-word'>" + I18n.t('activerecord.attributes.question.text') + '</span> '

      html_str << "<span class='number'>(#{display_number})</span> "

      html_str << "<span class='question'>" + q.text + '</span>'

      html_str
    end

  end

end
