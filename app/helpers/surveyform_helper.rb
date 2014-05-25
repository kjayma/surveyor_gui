module SurveyformHelper

  def list_dependencies(f)
    controlling_questions = f.object.controlling_questions

    count = controlling_questions.count
    retstr ='This question is shown depending on the '
    retstr += 'answer'.pluralize(count)
    retstr += ' to '
    retstr += 'question'.pluralize(count) + ' '
    retstr + list_phrase(controlling_questions.map{|q| q.question_number.to_s+')'})
  end

  def list_phrase(args)
    ## given a list of word parameters, return a syntactically correct phrase
    ## [dog] = "dog"
    ## [dog, cat] = "dog and cat"
    ## [dog, cat, bird] = "dog, cat and bird"
    case args.count
    when 0
      ''
    when 1
      args[0]
    when 2
      args[0] + ' and ' + args[1]
    else
      last = args.count
      args.take(last - 2).join(', ') + ', ' + args[last - 2] + ' and ' + args[last - 1]
    end
  end  
  
  def render_questions_and_groups_helper(q, ss)
    #this method will render either a question or a complete question group.
    #we always iterate through questions, and if we happen to notice a question
    #belongs to a group, we process the group at that time.
    #note that questions carry a question_group_id, and this is how we know
    #that a question is part of a group, and that it should not be rendered individually,
    #but as part of a group.  
    if q.object.part_of_group?
      _render_initial_group(q, ss)  ||  _respond_to_a_change_in_group_id(q, ss)
    else
      render "question_section", :f => q
    end  
  end
  
  def render_one_group(qg)
    qg.simple_fields_for :questions, @current_group.questions do |f|
      render "question_group_fields", f: f 
    end
  end
  
  def row_label_if_question_group(question)
    if question.part_of_group?
      "<span class=\"row_name\">#{question.text}: </span>".html_safe
    end
  end
  
  def question_group_class
    if @current_group.question_group.display_type == "grid"
      "grid"
    else
      "inline"
    end
  end
  
  private
  def _render_initial_group(q, ss)
    if @current_group.nil?
      @current_group = QuestionGroupTracker.new(q.object.question_group_id)
      render "question_group_section", :ss => ss, :q => q 
    end
  end
  
  def _respond_to_a_change_in_group_id(q, ss)
    if @current_group.question_group_id != q.object.question_group_id
      puts "group #{@current_group.question_group.text} id #{q.object.id} ss #{ss.object.id}"
      @current_group = QuestionGroupTracker.new(q.object.question_group_id)
      render "question_group_section", :ss => ss, :q => q 
    end
  end

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

class QuestionGroupTracker
  attr_reader :questions, :question_group_id, :question_group
  def initialize(question_group_id)
    @questions = Question.where('question_group_id=?',question_group_id)
    @counter = 0
    @question_group_id = question_group_id
    @question_group = QuestionGroup.find(question_group_id)
  end
end


