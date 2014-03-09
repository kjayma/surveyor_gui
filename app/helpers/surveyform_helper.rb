module SurveyformHelper

  def get_questions(f)
    question = f.object
    retstr = ''
    dependencies = []
    dependencies << question.dependency
    dependencies.each do |d|
      conditions = d.dependency_conditions
      conditions.each_with_index do |e, index|
        #if there is only one condition, end with the ')' - 'This question is shown depending on the answer to question 1)'
        if conditions.count == 1
          retstr += get_display_id(e.question_id).to_s+')'
        #if this is the last condition and there is more than one condition, add the word 'and' at the front 'This question is shown depending
        # on the answers to questions 1) and 2)'
        elsif (index+1) == conditions.count and conditions.count > 1
          retstr += 'and '+get_display_id(e.question_id).to_s+')'
        #if this is the next to last condition allow a space to be succeeded by the word 'and'
        elsif (index+1) == (conditions.count - 1)
          retstr += get_display_id(e.question_id).to_s+') '
        #if this is not the last condition, but part of a list of > 2 conditions, so include the comma 'This question is shown depending on the
        # answers to question 1), 2), and 3).'
        else
          retstr += get_display_id(e.question_id).to_s+'), '
        end
      end
    end
    if retstr.include?('and')
      retstr = 'This question is shown depending on the answers to questions '+retstr
    else
      retstr = 'This question is shown depending on the answer to question '+ retstr
    end
    return retstr
  end

  def get_display_id(q)
    target = Question.find(q)
    if target.survey_section_id.nil?
      return nil
    else
      previous = Question.joins(:survey_section).where(
        'survey_id = ? and survey_sections.display_order < ? and display_type != ?',
        target.survey_section.survey_id,
        target.survey_section.display_order,
        "label"
      )
      return previous.count + target.survey_section.questions.where('display_order <= ? and display_type != ?',target.display_order,"label").count
    end
  end

end

def clone_vendor_value_analysis_questionnaire
  template = Surveyform.where(:template=>true).where(:survey_type=>"VACQV").where(:evaluationrx_master=>true).first
  if !template
    template = Surveyform.where(:template=>true).where(:survey_type=>"VACQV").first
  end
  new_survey_id = clone_survey(template)
  return new_survey_id
end

def clone_hospital_value_analysis_questionnaire
  template = Surveyform.where(:template=>true).where(:survey_type=> "VACQH").where(:evaluationrx_master=>true).first
  if !template
    template = Surveyform.where(:template=>true).where(:survey_type=> "VACQH").first
  end
  new_survey_id = clone_survey(template)
  return new_survey_id
end

def clone_survey(template, as_template=false)
  #the built-in clone method provided by Ruby on Rails gets us a clone of the Survey model, but does not clone the nested models. We have to do that ourselves.
  s2 = template.dup
  s2.user_id = current_user.id
  question_table = {}
  answer_table = {}
  #build a clone by starting with the original survey template and traversing down through the nested template models of survey_section, question, answer, dependency, dependency condition.
  #any model with a suffix of '2' indicates the cloned model.

  #first, check if this is a Product Trial Questionnaire (PQ) and does not yet have mandatory EvaluationRx questions built in. If not, add them from the mandatory template before we add the
  #questions from the user selected template.
  if template.survey_type=='PQ'
    lacks_mandatory_questions = !template.survey_sections.map{|ss| ss.questions.collect(&:modifiable)}.flatten.include?(false)
    if lacks_mandatory_questions
      mandatory_survey = Survey.find_by_survey_type('MERXPQ')
      if mandatory_survey
        mandatory_survey.survey_sections.each do |ss|
          ss2 = s2.survey_sections.build(ss.attributes)
          ss.questions.each do |q|
            q2 = ss2.questions.build(q.attributes)
            q.answers.each do |a|
              a = q2.answers.build(a.attributes)
              a.original_choice = a.text
            end
            if q.dependency
              d2 = q2.build_dependency(q.dependency.attributes)
              q.dependency.dependency_conditions.each do |dc|
                #null dependency_id to avoid triggering validation on dup rules.
                dc2 = d2.dependency_conditions.build(dc.attributes.merge(:dependency_id => nil))
              end
            end
          end
        end
      end
    end
  end

  template.survey_sections.each do |ss|
    ss2 = s2.survey_sections.build(ss.attributes)
    if lacks_mandatory_questions
      # if we prepended mandatory questions, we need to add 1 to the display_order of all subsequent sections, so we don't have two sections with display_order=0
      ss2.display_order = ss2.display_order+1
    end
    ss2.survey_id = nil
    ss.questions.each do |q|
      q2 = ss2.questions.build(q.attributes)
      q.answers.each do |a|
        a = q2.answers.build(a.attributes)
        a.original_choice = a.text
      end
      if q.dependency
        d2 = q2.build_dependency(q.dependency.attributes)
        q.dependency.dependency_conditions.each do |dc|
          #null dependency_id to avoid triggering validation on dup rules.
          dc2 = d2.dependency_conditions.build(dc.attributes.merge(:dependency_id => nil))
        end
      end
    end
  end
  s2.template = as_template
  s2.access_code = s2.title+Time.now.to_s
  if s2.save
    #if we leave the clone as is, the cloned dependency_condition object will have foreign keys pointing to the original templates, not the cloned objects.
    #therefore the dependencies will act against the parent and not the clone. To correct this, we set up a cross reference by traversing the original models,
    #and building a table indexed by the original ids which contains a hash of each corresponding new id.

    #first do it for the mandatory questions, if applicable
    if mandatory_survey
      mandatory_survey.survey_sections.each_with_index do |ss, idx1|
        ss.questions.each_with_index do |q, idx2|
          question_table[q.id.to_s]={:new_id => s2.survey_sections[idx1].questions[idx2].id}
          q.answers.each_with_index do |a, idx3|
            answer_table[a.id.to_s]={:new_id => s2.survey_sections[idx1].questions[idx2].answers[idx3].id}
          end
        end
      end
    end


    template.survey_sections.each_with_index do |ss, idx1|
      ss.questions.each_with_index do |q, idx2|
        question_table[q.id.to_s]={:new_id => s2.survey_sections[idx1].questions[idx2].id}
        q.answers.each_with_index do |a, idx3|
          answer_table[a.id.to_s]={:new_id => s2.survey_sections[idx1].questions[idx2].answers[idx3].id}
        end
      end
    end
    #now we traverse the clone and reassign foreign keys in the dependency_condition object based on the cross reference table.
    s2.survey_sections.each do |ss|
      ss.questions.each do |q|
        if q.dependency
          q.dependency.dependency_conditions.each do |dc|
            dc.question_id = question_table[dc.question_id.to_s][:new_id]
            dc.answer_id = answer_table[dc.answer_id.to_s][:new_id]
            dc.save!
          end
        end
      end
    end
    return s2.id
  else
    return nil
  end

end 
