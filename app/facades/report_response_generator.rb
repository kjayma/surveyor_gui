class ReportResponseGenerator
  RESPONSE_GENERATOR = {
    pick_one: pick_one = ->(response, response_set, q, context){ context.send(:make_pick_one, response_set, q) },
    pick_any: pick_any = ->(response, response_set, q, context){ context.send(:random_anys, response, response_set, q) },
    dropdown: pick_one,
    slider:   pick_one,
    number:   ->(response, response_set, q, context){ response.integer_value = rand(100); response.save },
    string:   ->(response, response_set, q, context){ response.string_value = context.send(:random_string); response.save },
    box:      ->(response, response_set, q, context){ response.text_value = context.send(:random_string); response.save },
    date:     ->(response, response_set, q, context){ response.datetime_value = context.send(:random_date); response.save },
    datetime: ->(response, response_set, q, context){ response.datetime_value = context.send(:random_date); response.save },
    time:     ->(response, response_set, q, context){ response.datetime_value = context.send(:random_date); response.save },
    file:     ->(response, response_set, q, context){ context.send(:make_blob, response, false) },
    stars:    ->(response, response_set, q, context){ response_set.responses.create(:question_id => q.id, :integer_value => rand(5)+1, :answer_id => q.answers.first.id)},
    grid_one: pick_one,
    grid_any: pick_any,
    grid_dropdown: ->(response, response_set, q, context){ context.send(:grid_dropdown, response, response_set, q) }
  }

  def initialize(survey)
    @survey = survey
  end
  
  def generate_1_result_set(response_set)
    @survey.survey_sections.each do |ss|
      ss.questions.each do |q|
        response = response_set.responses.build(:question_id => q.id, :answer_id => q.answers.first ? q.answers.first.id : nil)
        if q.repeater?
          rand(5).times.each do 
            response = response_set.responses.build(:question_id => q.id, :answer_id => q.answers.first.id)
            RESPONSE_GENERATOR[q.question_type_id].call(response, response_set, q, self)
          end
        elsif q.question_type_id != :label
          RESPONSE_GENERATOR[q.question_type_id].call(response, response_set, q, self)
        end
      end
    end
  end


  def random_string
    whichone = rand(5)
    case whichone
    when 0
      'An answer.' # FIXME I18n
    when 1
      'A different answer.' # FIXME I18n
    when 2
      'Any answer here.' # FIXME I18n
    when 3
      'Some response.' # FIXME I18n
    when 4
      'A random response.' # FIXME I18n
    when 5
      'A random answer.' # FIXME I18n
    end
  end
  
  def random_date
    Time.now + (rand(100)-50).days
  end
  
  def random_pick(question, avoid=[])
    answer = nil
    answers = question.answers.is_not_comment
    while !answer && avoid.count < answers.count
      pick = rand(answers.count)
      if !avoid.include?(answers[pick].id)
        answer=answers[pick].id
      end
    end
    return answer
  end

  def make_pick_comment(response_set, q)
    comment = q.answers.is_comment
    if comment && !comment.empty?
      response_set.responses.create(question_id: q.id, answer_id: comment.first.id, string_value: "User added a comment here.") # FIXME I18n
    end
  end

  def make_pick_one(response_set, q)
    if q.is_comment?
      response_set.responses.create(question_id: q.id, answer_id: q.answers.first.id, string_value: "User added a comment here.") # FIXME I18n
    else
      response_set.responses.create(question_id: q.id, answer_id: random_pick(q)) 
      make_pick_comment(response_set, q)
    end
  end
  
  def random_pick_count(question)
    answers = question.answers
    return rand(answers.count)+1
  end

  def make_blob(response, show_blob)
    response.save!
    response.blob.store!(File.new(Rails.public_path+'/images/regulations.jpg')) if show_blob
  end

  def random_any(response, response_set, q)
    if !q.answers.empty?
      how_many = random_pick_count(q)
      how_many.times {
        already_checked = response_set.responses.where('question_id=?',q.id).collect(&:answer_id)
        response = response_set.responses.build(:question_id => q.id, :answer_id => random_pick(q,already_checked))
        response.save
      }
    else
      response = nil
    end
  end

  def random_anys(response, response_set, q)
    if q.is_comment?
      response_set.responses.create(question_id: q.id, answer_id: q.answers.first.id, string_value: "User added a comment here.") # FIXME I18n
    else    
      random_any(response, response_set, q)
      make_pick_comment(response_set, q)
    end
  end

  def grid_one(response, response_set, q)
    q.question_group.questions.each do |question|
      response = response_set.responses.build(question_id: question.id, answer_id: random_pick(question)) 
      response.save
    end
  end

  def random_pick_with_column(question, column)
    answers = Answer.where(question_id: question.id, column_id: column.id)
    pick = rand(answers.count)
    answer=answers[pick].id
  end

  def grid_dropdown(response, response_set, q)
    q.question_group.questions.is_not_comment.each do |question|
      q.question_group.columns.each do |column|
        response = response_set.responses.build(question_id: q.id, answer_id: random_pick_with_column(question, column), column_id: column.id )
        response.save
      end
    end
    if question = q.question_group.questions.is_comment.first && question && !question.empty?
      response_set.responses.create(question_id: question.id, answer_id: question.answers.first.id, column_id: column.id, string_value: "User added comment here") # FIXME I18n
    end
  end
  
end
