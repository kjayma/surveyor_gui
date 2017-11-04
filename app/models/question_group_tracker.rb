class QuestionGroupTracker

  attr_reader :questions, :question_group_id, :question_group


  def initialize(question_group_id)
    @questions = Question.where('question_group_id=?', question_group_id)
    @counter = 0
    @question_group_id = question_group_id
    @question_group = QuestionGroup.find(question_group_id)
  end


  def check_for_new_group(question)
    if question.question_group_id != @question_group_id || !defined?(@initial_check)
      initialize(question.question_group_id)
      @initial_check = true
      return true
    else
      return false
    end
  end
end
