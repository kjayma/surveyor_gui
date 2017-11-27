require 'complex'

include Math


class SurveyorGui::ReportsController < ApplicationController

  include ReportPreviewWrapper

  # ReportPreviewWrapper wraps preview in a database transaction so test data is not permanently saved.

  before_action :set_survey, only: [:show, :all_responses]

  around_action :wrap_in_transaction, only: :preview

  layout 'surveyor_gui/surveyor_gui_default'


  def preview

    response_qty = 5
    user_ids = response_qty.times.map { |i| -1*i }
    @title = I18n.t('surveyor_gui.reports.preview.title', response_qty: response_qty.to_s)
    @survey = Survey.find(params[:survey_id])

    user_ids.each do |user_id|
      @response_set = ResponseSet.create(survey: @survey, user_id: user_id, test_data: true)
      ReportResponseGenerator.new(@survey).generate_1_result_set(@response_set)
    end

    @response_sets = ResponseSet.where(survey_id: @survey.id, test_data: true).where('user_id in (?)', user_ids)
    @responses = Response.joins(:response_set, :answer).where('user_id in (?) and survey_id = ? and test_data = ? and answers.is_comment = ?', user_ids, params[:survey_id], true, false)

    if (!@survey)
      flash[:notice] = I18n.t('surveyor_gui.not_found', item: I18n.t('surveyor_gui.survey'))
      redirect_to :back
    end

    generate_report(params[:survey_id], true)
    render :show

  end


  def show
    @response_sets = ResponseSet.where(survey_id: @survey.id, test_data: false)
    @responses = Response.joins(:response_set, :answer).where('survey_id = ? and test_data = ? and answers.is_comment=?', @survey.id, false, false)
    @title = I18n.t('surveyor_gui.reports.show.title', survey_title: @survey.title)
    if @responses.count > 0
      generate_report(@survey.id, false)
    else
      flash[:error] = I18n.t('surveyor_gui.reports.show.no_responses')
      redirect_to surveyforms_path
    end
  end


  # the count for all responses, for all questions and answers
  def all_responses

    @chart = {}
    @show_section_titles = false # FIXME - need to config this for the survey

    @sections = @survey.survey_sections
    @questions = Question.includes(:answers).where(survey_section_id: @sections.map(&:id), is_comment: false)
    @answers = Answer.where(question_id: @questions.map(&:id), is_comment: false)

    @response_sets = ResponseSet.where(survey: @survey)

    @responses = Response.where(answer_id: @answers.map(&:id)).order(:answer_id)

    response_counts = Response.where(response_set_id: @response_sets.map(&:id)).group(:question_id).order(:question_id).group(:answer_id).count(:id)

    @response_counts_by_q = response_counts.group_by { |k, _v| k[0] }

    # this creates a nested Hash like this:
    #   [question_id, answer_id] => count
    # {
    #   [305, 1097]=>435,
    #   [305, 1098]=>109,
    #   [305, 1099]=>56,
    #   [306, 1104]=>35,
    #   [306, 1102]=>188,
    #   [306, 1100]=>53,
    #   [306, 1103]=>154,  ...

    # And we can access them in that form like this:
    #
    # response_counts_by_q.each do | k_question, v_answers |
    #  "QUESTION ID (key[0]): #{k_question[0]}  answer ID (key[1]) = #{k_question[1]}, count = #{v_answers}"
    # end

    # but we can re-organize them so they are easier to work with:
    @question_answers_counts = {}
    @response_counts_by_q.each do | k_qid, v_ka_count |
      v_ka_count.each do | each_v |
        a_id = each_v.first[1]
        count = each_v.last
        puts "  @question_answers_counts[k_qid =  #{@question_answers_counts[k_qid]}"
        @question_answers_counts.fetch(k_qid){ |ques_id| @question_answers_counts[ques_id] = {}}
        @question_answers_counts[k_qid].fetch(a_id){ |ans_id| @question_answers_counts[k_qid][ans_id] = count  }
      end

    end

    # Now they are in this handy form:
    #  question_id => { answer_id => count}
    #
    # [ {305=>{1097=>435, 1098=>109, 1099=>56}},
    #   {306=>{1104=>35, 1102=>188, 1100=>53, 1103=>154, 1101=>166}},
    #   {307=>{1108=>55, 1106=>78, 1107=>95, 1105=>368}},
    #    {308=>{1110=>57, 1109=>371, 1111=>165}},
    #    {309=>{1125=>65, 1124=>130, 1123=>397}},
    #    {310=>{1128=>366, 1130=>75, 1127=>170, 1129=>236, 1126=>51}},
    #    {311=>{1133=>146, 1132=>246, 1131=>199}},
    #    {312=>
    #         {1121=>7,
    #          1113=>3,
    #          1116=>4,
    #          1120=>7,
    #          1117=>2,
    #          1122=>11,
    #          1119=>9,
    #          1114=>2,
    #          1115=>1,
    #          1112=>7,
    #          1118=>4}
    #     }
    # ]

    @title = t('surveyor_gui.responses.all_responses_report.title')


    # The following is just an ActiveRecord_Relation. it doesn't hit the db for data
    # It will hit the db once to get the response count for ALL of the answers for ALL of these questions.
    #  (Then the info will be cached)

    all_answers = Answer.unscoped
                   .joins("LEFT OUTER JOIN responses ON responses.answer_id = answers.id")
                   .where(question_id: @questions.map(&:id))
                   .select("answers.question_id, answers.id, answers.text as text, answers.is_comment, count(responses.id) as answer_count")
                   .group("answers.question_id, answers.id, answers.text, answers.is_comment")
                   .order("answers.question_id, answers.id")

    set_chart_info(@questions, all_answers)

  end


  def generate_report(survey_id, test)


    # the following is just an ActiveRecord_Relation - it doesn't hit the db
    questions = Question.includes(:answers).joins(:survey_section).where('survey_sections.survey_id = ? and is_comment = ?', survey_id, false)

    # multiple_choice_responses = Response.joins(:response_set, :answer).where('survey_id = ? and test_data = ?',survey_id,test).group('responses.question_id','answers.id','answers.text').select('responses.question_id, answers.id, answers.text as text, count(*) as answer_count').order('responses.question_id','answers.id')

    # multiple_choice_responses = Answer.unscoped.joins(:question=>:survey_section).includes(:responses=>:response_set).where('survey_sections.survey_id=? and (response_sets.test_data=? or response_sets.test_data is null)',survey_id,test).group('answers.question_id','answers.id','answers.text').select('answers.question_id, answers.id, answers.text as text, count(*) as answer_count').order('answers.question_id','answers.id')

    # multiple_choice_responses = Answer.unscoped.find(:all,
    #     :joins => "LEFT JOIN responses ON responses.answer_id = answers.id",
    #     :select => "answers.question_id, answers.id, answers.text as text, count(answers.*) as answer_count",
    #     :group => "answers.question_id, answers.id, answers.text",
    #     :order => "answers.question_id, answers.id")

    # all_answers = Answer.where(question: questions.map(&:id))

    # The following is just an ActiveRecord_Relation. it doesn't hit the db for data
    # It will hit the db once to get the response count for ALL of the answers for ALL of these questions.
    #  (Then the info will be cached)
    multiple_choice_answers = Answer.unscoped.joins("LEFT OUTER JOIN responses ON responses.answer_id = answers.id
            LEFT OUTER JOIN response_sets ON response_sets.id = responses.response_set_id").
        joins(:question => :survey_section).
        where('survey_sections.survey_id=? and (response_sets.test_data=? or response_sets.test_data is null)', survey_id, test).
        select("answers.question_id, answers.id, answers.text as text, answers.is_comment, count(responses.id) as answer_count").
        group("answers.question_id, answers.id, answers.text, answers.is_comment").
        order("answers.question_id, answers.id")


=begin
   # not currently being used!
    single_choice_answers = Response.joins(:response_set).where('survey_id = ? and test_data = ?', survey_id, test).select('responses.question_id, responses.answer_id,
            responses.float_value,
            responses.integer_value,
            responses.datetime_value,
            responses.string_value')
=end
    @chart = {}

    @show_section_titles = false # FIXME - need to config this for the survey

    # single_choice_qs = questions.select{ | q | [:number, :date, :datetime, :time].include? q.question_type_id }
    # single_choice_as = Answer.joins(:question).where(question: single_choice_qs.map(&:id))

    # mult_choice_qs   = questions.reject{ | q | [:number, :date, :datetime, :time].include? q.question_type_id }
    # mult_choice_as = Answer.joins(:question).where(question: mult_choice_qs.map(&:id))


    set_chart_info(questions, multiple_choice_answers)


  end


  private

  def set_survey
    @survey = Survey.find(params[:id]) if params.has_key? :id
  end


  def set_chart_info(questions, all_answers)

    questions.each do |q|
      # will hit the db even if we do this in memory with a .group_by, so might as well us the db version to accomplish it:  Is this only used in 1 case below?
      #answers = Answer.unscoped.joins(:question).where(question: q).group(:question_id, :id, :text, :is_comment).order(:question_id, :id)

      #answers.each{|a| puts "response count: #{a.responses.count}"}

      # this should be a case statement!
      if [:grid_one, :grid_any].include? q.question_type_id
        # questions might be comments, and answers might be comments
        # question_group_stacked_bar_chart( q.question_group, multiple_choice_responses )
        generate_stacked_bar_chart(q, all_answers)

      elsif q.question_type_id == :grid_dropdown
        # questions cannot be comments, but answers might be
        q.question_group.questions.where(is_comment: false).each do |question|
          generate_grid_dropdown_bar_chart(question, all_answers)
        end

      elsif q.pick == 'one'
        # only work with answers where is_comment: false
        generate_pie_chart(q, all_answers)

      elsif q.pick == 'any'
        # only work with answers where is_comment: false
        generate_bar_chart(q, all_answers)

      elsif [:number, :date, :datetime, :time].include? q.question_type_id
        # only work with answers where is_comment: false

        # generate_histogram_chart(q, single_choice_responses)
        #  generate_bar_chart(q, single_choice_answers)
        # generate_bar_chart( q, multiple_choice_answers )

        answers = Answer.unscoped.includes(:responses).joins(question: :survey_section).where('questions.id = ?', q.id).is_not_comment.all

        simple_histogram q, answers

      end

    end


  end


  def generate_chart(q, answer_info, chart_method)

    data_array = chart_data_for_answer_info_in_q(answer_info, q)

    @chart[q.id.to_s] = chart_info chart_method, data_array, { label: q.text }

  end


  # We assume that these are ruby objects, not DB ActiveRecord Associations or related objects
  #
  def chart_data_for_answer_info_in_q(answer_info, q)

    data_array = []

    # select only the responses that are for this particular question
    #  get the count for the # of responses for this answer

    # ans.answer_count == Response.where(answer: ans).count

    answer_info.select { |a| a.question_id == q.id }.each_with_index do |ans, index|
      data_array[index]= [ans.text.to_s, ans.answer_count.to_i] unless ans.is_comment?
    end

    data_array

  end


  def generate_pie_chart(q, answer_info)
    generate_chart q, answer_info, :pie_chart
  end


  def generate_bar_chart(q, answer_info)
    generate_chart q, answer_info, :bar_chart
  end


  # stacked bar chart for a question group. categories = all answer_info in the group. bars = questions
  def question_group_stacked_bar_chart(q_group, answer_info)

    # StackOverflow answer: how to set up the data for chartkick stacked bar chart?
    # @see https://stackoverflow.com/a/24388877

    questions = q_group.questions.reject(&:is_comment)

    categories = q_group.answers.map { |a| a.text }

    data_array = []
    questions.each do |q|

      q_data = chart_data_for_answer_info_in_q(answer_info, q)

      data_array << { name: q.text, data: q_data }

    end

    @chart[q.id.to_s] = chart_info :column_chart, data_array, { label: q.text, stacked: true }

  end


  def simple_histogram(q, answers)

    data_array = []

    #  get the count for the # of responses for this answer

    data_array = answers.includes(:responses).map { |a| [a.text, a.responses.count] }

    @chart[q.id.to_s] = chart_info :column_chart, data_array, { label: q.text }

  end


  # each bar has all the questions in a question group
  def generate_stacked_bar_chart(q, answer_info)

    # StackOverflow answer: how to set up the data for chartkick stacked bar chart?
    # @see https://stackoverflow.com/a/24388877

    q_group = q.question_group

    questions = q_group.questions.reject(&:is_comment)

    categories = q_group.answers.map { |a| a.text }

    data_array = []
    questions.each do |quest|

      q_data = chart_data_for_answer_info_in_q(answer_info, quest)

      data_array << { name: quest.text, data: q_data }

    end

    @chart[q.id.to_s] = chart_info :column_chart, data_array, { label: q.text, stacked: true }

=begin

    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = 'column'

      f.options[:title][:text] = q.question_group.text

      f.options[:xAxis][:categories] = q.answers.order('answers.id').map { |a| a.text }
      f.options[:xAxis][:labels] = { :rotation => -45, :align => 'right' }

      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = { :text => 'Count' }

      f.plot_options(
          :column => {
              :stacking => 'normal',
              dataLabels: {
                  enabled: true,
                  color: 'black',
                  style: {
                      fontWeight: 'bold',
                      fontSize: '12px'
                  }
              }
          }
      )

      q.question_group.questions.where(is_comment: false).each_with_index do |question, question_index|

        bararray = []
        responses.where(:question_id => question.id).each_with_index do |a, answer_index|
          bararray[answer_index]= { :y => a.answer_count.to_i }
        end


        f.series(
            name: question.text,
            data: bararray,
            color: colors[question_index].to_s
        )
      end

    end
=end

  end


  # bar chart using the question group columns as categories
  def generate_grid_dropdown_bar_chart(q, responses)

    data_array = []

    categories = q.question_group.columns.map { |c| c.text }

    resp_count_series = []

    q_group = q.question_group
    group_responses = q_group.responses

    q_group.columns.each_with_index do |column, column_index|

      q.answers.select { |a| a.column_id == column.id }.each_with_index do |answer, answer_index|

        # Response.where(question_id: q.id, answer_id: answer.id, column_id: column.id).count

        responses_ans_col = group_responses.select { |g_resp| g_resp.question.id == q.id && g_resp.answer.id == answer.id && g_resp.try(:column).try(:id) == column.id }
        response_count = responses_ans_col.count

        # count of the # of responses for this column and this answer and this question
        resp_count_series << { column_id: column.id, answer_id: answer.id, name: answer.text, count: response_count.to_i }
      end

    end

    # why not take care of this in the above loop?
    series_names = resp_count_series.map { |a| a[:name] }.uniq

    series_names.each do |answer_name|

      bar_data = []

      # get all of the possible answers for this column
      q_group.columns.each do |column|

        match_ans_and_col = resp_count_series.select { |s| s[:name] == answer_name && s[:column_id] == column.id }.first

        # select only the responses that are for this particular question
        #  get the array of [name, count for the # of responses for this answer ]
        #q_data = chart_data_for_responses_in_q( responses, quest )

        bar_data << match_ans_and_col[:count] unless match_ans_and_col.empty?

      end

      data_array << { name: answer_name, data: bar_data }

    end

    @chart[q.id.to_s] = chart_info :bar_chart, data_array, { label: q.text, stacked: true }


=begin
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|

      f.options[:chart][:defaultSeriesType] = 'column'
      f.options[:title][:text] = q.text

      f.options[:xAxis][:categories] = q.question_group.columns.map { |c| c.text }
      f.options[:xAxis][:labels] = { :rotation => -45, :align => 'right' }

      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = { :text => 'Count' }

      f.plot_options(
          :column => {
              :stacking => 'normal',
              dataLabels: {
                  enabled: true,
                  color: 'black',
                  style: {
                      fontWeight: 'bold',
                      fontSize: '12px'
                  }
              }
          },
          :pointPadding => true,
          :borderWidth => 0,
          :enableMouseTracking => false,
          :shadow => false,
          :animation => false,
          :stickyTracking => false
      )

      series = []

      q.question_group.columns.each_with_index do |column, column_index|
        q.answers.where(column_id: column.id).each_with_index do |answer, answer_index|
          response_count = Response.where(question_id: q.id, answer_id: answer.id, column_id: column.id).count
          series<<{ column_id: column.id, answer_id: answer.id, name: answer.text, y: response_count.to_i }
        end
      end

      series.map { |a| a[:name] }.uniq.each_with_index do |answer_name, answer_index|

        bararray=[]
        q.question_group.columns.each do |column|
          match = series.select { |s| s[:name]==answer_name && s[:column_id]==column.id }.first
          bararray << (match ? match[:y] : 0)
        end

        f.series(
            name: answer_name,
            data: bararray,
            color: colors[answer_index].to_s
        )
      end
    end
=end

  end


  # show intervals with statistics for the # of responses for the question
  #  (a.k.a "intervals with box plots" or 'box and whiskers' charts)
  def generate_histogram_chart(q, responses)

    suffix = q.suffix

    responses = q.responses

    # helpful charting info with the labels set and statistics
    histarray = HistogramArray.new(q, responses.where(:question_id => q.id), suffix).calculate

=begin
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = 'column'
      f.options[:title][:text] = 'Histogram for "' + q.text + '"'
      f.options[:legend][:enabled] = false
      f.options[:xAxis][:categories] = histarray.map { |h| h[:x] }
      f.options[:xAxis][:labels] = { :rotation => -45, :align => 'right' }
      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = { :text => 'Occurrences' }
      f.plot_options(
          :pointPadding => true,
          :borderWidth => 0,
          :enableMouseTracking => false,
          :shadow => false,
          :animation => false
      )
      f.series(:data => histarray.map { |h| h[:y] },
               :dataLabels => {
                   :enabled => true
               }
      )
    end
=end

  end


  # return the info in the form needed so we can pass it to chartkick charts in the view
  def chart_info(method, data, options = {})

    { method: method, data: data, options: options.merge(Chartkick.options) }
  end


  def report_params
    @report_params ||= params.permit(:survey_id, :id)
  end


end


# A simple helper class that holds the # of responses for each answer, for a question
class AnswerCountInfo

  attr_accessor :question, :answer, :response_count, :display_text

end


# A simple helper class takes an array of responses for a question and
#  creates an object with easy access to the labels and stats needed to create a chart
#  and pre-calculated stats (average, min, max, count)
#
# Uses ReportFormatter to create a helpful X-axis label based on the upper and lower bounds of the data
#
class HistogramArray

  # notes that response must be Response (not some version of Answers or anything else)
  def initialize(question, responses, label=nil)

    # array of values based on the @distribution
    @out_arr = []
    # p "in arr at init #{in_arr.map { |a| a }}"

    # all possible response values
    @in_arr = responses.map { |r| r.response_value }
    return if responses.empty?

    @question = question
    @responses = responses

    set_min
    set_max
    set_count
    set_distribution
    set_step
  end


  # return a collection of [name, count] for each response to the question
  # the 'name' is the response answer text
  def data_counts

    if @data_counts.nil?

      data_array = []

      #  get the count for the # of responses for for each answer to this question
      @responses.each_with_index do |r, index|
        data_array[index]= [r.text.to_s, r.answer_count.to_i] unless r.is_comment?
      end

      data_array

    else
      @data_counts
    end

  end


  def calculate

    unless @in_arr.empty?

      @distribution.times do |index|

        refresh_range
        set_x_label

        @out_arr[index]= {
            :x => @x_label,
            :y => @in_arr.select { |v| v.to_f >= @lower_bound && v.to_f < @upper_bound }.count
        }
      end

    end

    @out_arr

  end


  private

  def set_min
    @min = @range = @in_arr.min.to_f
  end


  def set_max
    @max = @in_arr.max.to_f
    @max = @max + @max.abs * 0.00000000001
  end


  def set_count
    @count = @in_arr.count
  end


  def set_distribution
    @distribution = sqrt(@count).round
  end


  def set_step
    @step = ((@max-@min) / @distribution)
  end


  def refresh_range
    @lower_bound = @range
    @upper_bound = @range + @step
    @range = @upper_bound
  end


  def trunc_range(num)
    (num * 10000000000).to_i / 10000000000
  end


  def set_x_label

    if @question.question_type_id == :number
      @x_label = trunc_range(@lower_bound).to_s + ' to ' + trunc_range(@upper_bound).to_s + ' ' + @label.to_s

    else
      response_formatter = ReportFormatter.new(@question, @in_arr)

      lower_bound = response_formatter.format_stats(@lower_bound)
      upper_bound = response_formatter.format_stats(@upper_bound)
      @x_label = lower_bound + ' to ' + upper_bound + ' ' + @label.to_s
    end

  end


end
