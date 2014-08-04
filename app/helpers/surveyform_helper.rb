module SurveyformHelper

  def list_dependencies(o)
    controlling_questions = o.controlling_questions

    controlling_question_ids = controlling_questions.map{|q| q.question_number.to_s+')'}.uniq
    count = controlling_question_ids.count
    retstr ='This question is shown depending on the '
    retstr += 'answer'.pluralize(count)
    retstr += ' to '
    retstr += 'question'.pluralize(count) + ' '
    retstr + list_phrase(controlling_question_ids)
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
      render "question_wrapper", f: q
    end  
  end
  
  def render_one_group(qg)
    qg.simple_fields_for :questions, @current_group.questions do |f|
      if f.object.is_comment != true
        render "question_group_fields", f: f
      elsif f.object.is_comment == true
        "</div>".html_safe+(render "question_field", f: f)+"<div>".html_safe
      end 
    end
  end  
  
  def question_group_heading(f)
    if f.object.question_type_id == :grid_dropdown
      heading = f.object.question_group.columns
    elsif f.object.question_group.display_type == "grid"
      heading = f.object.answers
    else
      heading = []
    end  
    heading.map {|a| "<span class=\"question_group_heading #{f.object.question_type_id.to_s}\" >#{a.text}<\/span>"}.join().html_safe
  end  
  
  def row_label_if_question_group(question)
    if question.part_of_group? 
      "<span class=\"row_name\">#{question.text}: </span>".html_safe
    end
  end
  
  def question_group_class(question)
    if @current_group.question_group.display_type == "inline"
      "inline"
    elsif @current_group.question_group.display_type == "default"
      "default"
    else
      if question.question_type_id == :grid_dropdown
        "dropdown"
      else
        "grid"
      end
    end
  end
  
  private
  def _render_initial_group(q, ss)
    if @current_group.nil?
      @current_group = QuestionGroupTracker.new(q.object.question_group_id)
      render "question_group", :ss => ss, :f => q 
    end
  end
  
  def _respond_to_a_change_in_group_id(q, ss)
    if @current_group.question_group_id != q.object.question_group_id
      @current_group = QuestionGroupTracker.new(q.object.question_group_id)
      render "question_group", :ss => ss, :f => q 
    end
  end

end

class SurveyCloneFactory
  def initialize(id, as_template=false)
    @template = Surveyform.find(id.to_i)
    @as_template = as_template
  end

  def clone
    #the built-in clone method provided by Ruby on Rails gets us a clone of the Survey model, but does not clone the nested models. We have to do that ourselves.
    s2 = @template.dup
    s2.api_id = Surveyor::Common.generate_api_id
    s2.survey_version = Survey.where(access_code: @template.access_code).maximum(:survey_version) + 1
    #s2.user_id = current_user.id
    question_table = {}
    answer_table = {}
    question_group_table = {}
    columns_table = {}
    #build a clone by starting with the original survey @template and traversing down through the nested @template models of survey_section, question, answer, dependency, dependency condition.
    #any model with a suffix of '2' indicates the cloned model.
  
    @template.survey_sections.each do |ss|
      ss2 = s2.survey_sections.build(ss.attributes)
      ss2.survey_id = nil
      ss2.id        = nil
      ss2.modifiable = true
      ss.questions.each do |q|
        q2 = ss2.questions.build(q.attributes)
        q2.survey_section_id = nil
        q2.id = nil
        q2.api_id = Surveyor::Common.generate_api_id        
        q.answers.each do |a|
          a = q2.answers.build(a.attributes)
          a.question_id = nil
          a.id = nil
          a.api_id = Surveyor::Common.generate_api_id
          a.original_choice = a.text
        end
        if q.dependency
          d2 = q2.build_dependency(q.dependency.attributes)
          d2.question_id = nil
          d2.id = nil
          q.dependency.dependency_conditions.each do |dc|
            #null dependency_id to avoid triggering validation on dup rules.
            dc2 = d2.dependency_conditions.build(dc.attributes.merge(:id=> nil, :dependency_id => nil))
          end
        end
      end
    end

    s2.template = @as_template
    #s2.access_code = s2.title+Time.now.to_s
    if s2.save
      #if we leave the clone as is, the cloned dependency_condition object will have foreign keys pointing to the original @templates, not the cloned objects.
      #therefore the dependencies will act against the parent and not the clone. To correct this, we set up a cross reference by traversing the original models,
      #and building a table indexed by the original ids which contains a hash of each corresponding new id.
  
      @template.survey_sections.each_with_index do |ss, idx1|
        ss.questions.each_with_index do |q, idx2|
          question_table[q.id.to_s]={:new_id => s2.survey_sections[idx1].questions[idx2].id}
          q.answers.each_with_index do |a, idx3|
            answer_table[a.id.to_s]={:new_id => s2.survey_sections[idx1].questions[idx2].answers[idx3].id}
          end
        end
      end

      question_groups = @template.survey_sections.map{|ss| ss.questions.map{|q| q.question_group}}.flatten.uniq.delete_if{|qg| qg.nil?}
      question_groups = (question_groups.count == 1 && question_groups[0].nil?) ? [] : question_groups
      question_groups.each do |qg|
        qg2 = QuestionGroup.new(qg.attributes)
        qg2.id = nil
        qg2.api_id = Surveyor::Common.generate_api_id
        qg.columns.each do |col|
          col2 = qg2.columns.build(col.attributes.merge(:id=>nil, :question_group_id => nil))         
        end
        qg2.save!
        qg2.reload
        question_group_table[qg.id.to_s] = {:new_id => qg2.id}
        qg.columns.each_with_index do |col, idx1|
          columns_table[col.id.to_s] = {:new_id => qg2.columns[idx1].id}
        end
      end

      #now we traverse the clone and reassign foreign keys in question_groups and the dependency_condition object based on the cross reference table.
      s2.survey_sections.each do |ss|
        ss.questions.each do |q|
          if q.part_of_group?
            q.update_attributes(question_group_id: question_group_table[q.question_group_id.to_s][:new_id])
            q.answers.each do |a|
              if a.column_id
                p "a #{a.id} a.colid #{a.column_id} table #{columns_table}"
                a.update_attributes(column_id: columns_table[a.column_id.to_s][:new_id])
              end
            end
          end
          if q.dependency
            q.dependency.dependency_conditions.each do |dc|
              dc.question_id = question_table[dc.question_id.to_s][:new_id]
              dc.answer_id = answer_table[dc.answer_id.to_s][:new_id] if dc.answer_id
              dc.save!
            end
          end
        end
      end

      return s2
    else
      raise s2.errors.messages.map{|m| m}.join(',')
      return nil
    end
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


