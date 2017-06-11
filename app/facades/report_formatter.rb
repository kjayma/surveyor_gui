class ReportFormatter

  STAT_FUNCTIONS = {
      sum: ->(arr) { arr.sum },
      min: ->(arr) { arr.min },
      max: ->(arr) { arr.max },
      average: ->(arr) { arr.average }
  }

  STAT_FORMATS = {
      number: "%g",
      date: "%m-%d-%y",
      time: "%I:%M:%S %P",
      datetime: "%m-%d-%y %I:%M:%S %P"
  }


  def initialize(question, responses)
    @question = question
    @responses = responses
  end


  def stats(stat_function)
    stat = calculate_stats(stat_function)
    format_stats(stat)
  end


  def calculate_stats(stat_function)
    arr = @responses.where(:question_id => @question.id).map { |r| r.response_value.to_f }
    STAT_FUNCTIONS[stat_function].call(arr)
  end


  def format_stats(stat)
    if @question.question_type_id == :number
      STAT_FORMATS[@question.question_type_id] % stat.to_f
    elsif [:date, :datetime, :time].include? @question.question_type_id
      format_time_stat(stat.to_f)
    else
      stat
    end
  end


  def format_time_stat(stat)
    stat = Time.zone.at(stat)
    stat.strftime(STAT_FORMATS[@question.question_type_id])
  end
end
