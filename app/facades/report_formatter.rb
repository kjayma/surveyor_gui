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
    calculate_stats_responses_arr(stat_function, arr)
  end


  def calculate_stats_responses_arr(stat_function, responses_arr)
    STAT_FUNCTIONS[stat_function].call(responses_arr)
  end


  def format_stats(stat)
    format_stats_q_type(stat, @question.question_type_id)
  end


  def format_stats_q_type(stat, q_type)
    if q_type == :number
      STAT_FORMATS[q_type] % stat.to_f
    elsif [:date, :datetime, :time].include? q_type
      format_time_stat(stat.to_f)
    else
      stat
    end
  end


  def format_time_stat(stat)
    format_time_stat_q_type(stat, @question.question_type_id)
  end


  def format_time_stat_q_type(stat, q_type)
    stat = Time.zone.at(stat)
    stat.strftime(STAT_FORMATS[q_type])
  end
end
