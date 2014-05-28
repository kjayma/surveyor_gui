class Surveyform < Survey
  def self.search(search)
    search ? where('title LIKE ?', "%#{search}%") : all
  end
  
  def sort_as_per_array(serialized_sort_data)
    question_sorter = QuestionSorter.new
    _iterate_survey_sections(serialized_sort_data, question_sorter)
    survey_section_questions = survey_sections.collect(&:questions)
    question_sorter.rearrange(survey_section_questions)

  end

  
  def _iterate_survey_sections(serialized_sort_data, question_sorter)
    # from data in the form of
    # {"sortable_question<survey_section_id>": {
    #   <question_id>,
    #   <question_id>,
    #   etc.
    # }
    #
    # build a hash in the form of 
    #  {<question_id>: {
    #     "survey_section_id":  <survey_section_id>,
    #     "display_order":      <display_order>
    #     }
    #   }   
    serialized_sort_data.each do |(survey_section_identifier, questions)|
      if survey_section_identifier.include? "sortable_question"
        survey_section_id = /\d+/.match(survey_section_identifier).to_s
        questions.delete("id") #for some reason, question groups introduce values of "id" into array.
        _iterate_questions(questions, survey_section_id, question_sorter)
      end
    end
  end
  
  def _iterate_questions(questions, survey_section_id, question_sorter)
    questions.each do |question_id|
      question = Question.find(question_id.to_i)
      if question.part_of_group?
        _process_question_group(question, survey_section_id, question_sorter)
      else
        _process_individual_question(question, survey_section_id, question_sorter)
      end
    end
  end
  
  def _process_question_group(question, survey_section_id, question_sorter)
    question_group = question.question_group
    question_group.questions.each do |question|
      _process_individual_question(question, survey_section_id, question_sorter)
    end
  end
  
  def _process_individual_question(question, survey_section_id, question_sorter)
    question_sorter.push(question.id.to_s, survey_section_id)
  end
  
end

class QuestionSorter
  def initialize
    @sorting_hash   = {}
    @display_order  = 0
    @qoffset        = 0
  end
  
  def push(id, survey_section_id)
    @sorting_hash[id.to_s] = {survey_section_id: survey_section_id, display_order: @display_order}
    _increment_display_order
  end
    
  def rearrange(survey_sections)    
    survey_sections.each do |survey_section|
      survey_section.each do |question|
        _update_question(survey_section, question)
      end
    end     
  end
  
  private
   
  def _increment_display_order
    @display_order += 1
  end
  
  def _update_question(survey_section, question)
    question_id           = question.id.to_s   

    new_display_order     = @sorting_hash[question_id][:display_order]
    new_section_id        = @sorting_hash[question_id][:survey_section_id].to_i
    old_display_order     = question.display_order
    old_section_id        = question.survey_section_id
    
    if old_display_order != new_display_order || old_section_id != new_section_id
      question.update_attributes!(
        display_order:      new_display_order,
        survey_section_id:  new_section_id
      )
    end
  end
end
