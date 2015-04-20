require 'complex'
include Math

class SurveyorGui::ReportsController < ApplicationController
  include ReportPreviewWrapper

  # ReportPreviewWrapper wraps preview in a database transaction so test data is not permanently saved.
  around_action :wrap_in_transaction, only: :preview
  layout 'surveyor_gui/surveyor_gui_default'

  def preview
    response_qty = 5 
    user_ids = response_qty.times.map{|i| -1*i}
    @title = "Preview Report for "+response_qty.to_s+" randomized responses"
    @survey = Survey.find(params[:survey_id])
    user_ids.each do |user_id|
      @response_set = ResponseSet.create(survey: @survey, user_id: user_id, test_data: true)
      ReportResponseGenerator.new(@survey).generate_1_result_set(@response_set)
    end
    @response_sets = ResponseSet.where(survey_id: @survey.id, test_data: true).where('user_id in (?)', user_ids)
    @responses = Response.joins(:response_set, :answer).where('user_id in (?) and survey_id = ? and test_data = ? and answers.is_comment = ?',user_ids,params[:survey_id],true, false)
    if (!@survey)
      flash[:notice] = "Survey/Questionnnaire not found."
      redirect_to :back
    end
    generate_report(params[:survey_id], true)
    render :show    
  end

  def show
    @survey = Survey.includes({
      response_sets: [responses: [question: [:answers]]],
      survey_sections: [questions: [:answers, responses: [:response_set, :answer]]]
    }).find(params[:id])
    @response_sets = @survey.response_sets.select { |rs| !rs.test_data }
    @responses = @response_sets.flat_map(&:responses).select { |r| !r.is_comment }
    @title = "Show report for #{@survey.title}"
    if @responses.count > 0
      generate_report(@survey.id, false)
    else
      flash[:error] = "No responses have been collected for this survey"
      redirect_to surveyforms_path 
    end
  end

  def generate_report(survey_id, test)
    questions = Question.joins(:survey_section).where('survey_sections.survey_id = ? and is_comment = ?', survey_id, false)
# multiple_choice_responses = Response.joins(:response_set, :answer).where('survey_id = ? and test_data = ?',survey_id,test).group('responses.question_id','answers.id','answers.text').select('responses.question_id, answers.id, answers.text as text, count(*) as answer_count').order('responses.question_id','answers.id')
 
# multiple_choice_responses = Answer.unscoped.joins(:question=>:survey_section).includes(:responses=>:response_set).where('survey_sections.survey_id=? and (response_sets.test_data=? or response_sets.test_data is null)',survey_id,test).group('answers.question_id','answers.id','answers.text').select('answers.question_id, answers.id, answers.text as text, count(*) as answer_count').order('answers.question_id','answers.id')

# multiple_choice_responses = Answer.unscoped.find(:all,
# :joins => "LEFT JOIN responses ON responses.answer_id = answers.id",
# :select => "answers.question_id, answers.id, answers.text as text, count(answers.*) as answer_count",
# :group => "answers.question_id, answers.id, answers.text",
# :order => "answers.question_id, answers.id")

    multiple_choice_responses = Answer.unscoped.joins("LEFT OUTER JOIN responses ON responses.answer_id = answers.id
LEFT OUTER JOIN response_sets ON response_sets.id = responses.response_set_id").
                                                joins(:question=>:survey_section).
                                                where('survey_sections.survey_id=? and (response_sets.test_data=? or response_sets.test_data is null)',survey_id,test).
                                                select("answers.question_id, answers.id, answers.text as text, answers.is_comment, count(responses.id) as answer_count").
                                                group("answers.question_id, answers.id, answers.text, answers.is_comment").
                                                order("answers.question_id, answers.id")

    single_choice_responses = Response.joins(:response_set).where('survey_id = ? and test_data = ?',survey_id,test).select('responses.question_id, responses.answer_id,
responses.float_value,
responses.integer_value,
responses.datetime_value, 
responses.string_value')
    @chart = {}
    colors = ['#4572A7', '#AA4643', '#89A54E', '#80699B', '#3D96AE', '#DB843D', '#92A8CD', '#A47D7C', '#B5CA92']
    questions.each do |q|
      if [:grid_one, :grid_any].include? q.question_type_id
          generate_stacked_bar_chart(q, multiple_choice_responses, colors)
      elsif q.question_type_id == :grid_dropdown
        q.question_group.questions.where(is_comment: false).each do |question|
            generate_grid_dropdown_bar_chart(question, multiple_choice_responses, colors)
          end
      elsif q.pick == 'one'
          generate_pie_chart(q, multiple_choice_responses)
      elsif q.pick == 'any'
          generate_bar_chart(q, multiple_choice_responses, colors)
      elsif [:number,:date,:datetime,:time].include? q.question_type_id
          generate_histogram_chart(q, single_choice_responses)
      end
    end
  end

  private

  def generate_pie_chart(q, responses)
    piearray = []
    responses.where(:question_id => q.id).each_with_index do |a, index|
      piearray[index]= {:y=> a.answer_count.to_i, :name => a.text.to_s} if !a.is_comment?
    end
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:plotBorderWidth] = nil
      f.options[:chart][:plotBackgroundColor] = nil
      f.options[:title][:text] = q.text
      f.plot_options(:pie=>{
        :allowPointSelect=>true,
        :cursor=>"pointer" ,
        :dataLabels=>{
          :enabled=>true,
          :color=>"#000000",
          :connectorColor=>"#000000"
        },
        :enableMouseTracking => false,
        :shadow => false,
        :animation => false
      })
      f.series( :type => 'pie',
        :name=> q.text,
        :data => piearray
      )
    end
  end
  
  def generate_bar_chart(q, responses, colors)
    bararray = []
    responses.where(:question_id => q.id).each_with_index do |a, index|
      bararray[index]= {:y=> a.answer_count.to_i, :color => colors[index].to_s} if !a.is_comment?
    end
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = 'column'
      f.options[:title][:text] = q.text
      f.options[:xAxis][:categories] = q.answers.order('answers.id').map{|a| a.text}
      f.options[:xAxis][:labels] = {:rotation=> -45, :align => 'right'}
      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = {:text => 'Count'}
      f.plot_options(
        :pointPadding=>true,
        :borderWidth => 0,
        :enableMouseTracking => false,
        :shadow => false,
        :animation => false,
        :stickyTracking => false
      )
      f.series( :data => bararray,
        :dataLabels => {
          :enabled=>true
          } )
    end
  end

  def generate_stacked_bar_chart(q, responses, colors)
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = 'column'
      f.options[:title][:text] = q.question_group.text
      f.options[:xAxis][:categories] = q.answers.order('answers.id').map{|a| a.text}
      f.options[:xAxis][:labels] = {:rotation=> -45, :align => 'right'}
      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = {:text => 'Count'}
      f.plot_options(
        :column => {
          :stacking => 'normal',
          dataLabels:  {
            enabled: true,
            color: 'black',
            style: {
              fontWeight: 'bold',
              fontSize: '12px'
            }         
          }
        },
        :pointPadding=>true,
        :borderWidth => 0,
        :enableMouseTracking => false,
        :shadow => false,
        :animation => false,
        :stickyTracking => false
      )

      q.question_group.questions.where(is_comment: false).each_with_index do |question, question_index|
        bararray = []
        responses.where(:question_id => question.id).each_with_index do |a, answer_index|
          bararray[answer_index]= {:y=> a.answer_count.to_i}
        end
        f.series( 
          name: question.text,
          data: bararray,
          color: colors[question_index].to_s
        )
      end
    end
  end 
 
  def generate_grid_dropdown_bar_chart(q, responses, colors)
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = 'column'
      f.options[:title][:text] = q.text
      f.options[:xAxis][:categories] = q.question_group.columns.map{|c| c.text}
      f.options[:xAxis][:labels] = {:rotation=> -45, :align => 'right'}
      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = {:text => 'Count'}
      f.plot_options(
        :column => {
          :stacking => 'normal',
          dataLabels:  {
            enabled: true,
            color: 'black',
            style: {
              fontWeight: 'bold',
              fontSize: '12px'
            }     
          }
        },
        :pointPadding=>true,
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
          series<<{column_id: column.id, answer_id: answer.id, name: answer.text, y: response_count.to_i}
        end
      end
      series.map{|a| a[:name]}.uniq.each_with_index do |answer_name, answer_index|
        bararray=[]
        q.question_group.columns.each do |column|
          match = series.select{|s| s[:name]==answer_name && s[:column_id]==column.id}.first
          bararray << (match ? match[:y] : 0) 
        end
        f.series( 
          name: answer_name,
          data: bararray,
          color: colors[answer_index].to_s
        )      
      end
    end
  end 

  def generate_histogram_chart(q, responses)
    suffix = q.suffix
    histarray = HistogramArray.new(q, responses.where(:question_id => q.id), suffix).calculate
    @chart[q.id.to_s] = LazyHighCharts::HighChart.new('graph') do |f|
      f.options[:chart][:defaultSeriesType] = 'column'
      f.options[:title][:text] = 'Histogram for "'+q.text+'"'
      f.options[:legend][:enabled] = false
      f.options[:xAxis][:categories] = histarray.map{|h| h[:x]}
      f.options[:xAxis][:labels] = {:rotation=> -45, :align => 'right'}
      f.options[:yAxis][:min] = 0
      f.options[:yAxis][:title] = {:text => 'Occurrences'}
      f.plot_options(
        :pointPadding=>true,
        :borderWidth => 0,
        :enableMouseTracking => false,
        :shadow => false,
        :animation => false
      )
      f.series( :data=> histarray.map{|h| h[:y]},
        :dataLabels => {
          :enabled=>true
          }
              )
    end
  end

  def report_params 
    @report_params ||= params.permit(:survey_id, :id)
  end
      
end

class HistogramArray
  def initialize(question, in_arr, label=nil)
    @out_arr = []
    p "in arr at init #{in_arr.map{|a| a}}"
    @in_arr = in_arr.map{|a| a.response_value}
    return if in_arr.empty?
    @question = question
    set_min
    set_max
    set_count
    set_distribution
    set_step
  end

  def calculate
    if !@in_arr.empty?
      @distribution.times do |index|
        refresh_range
        set_x_label
        @out_arr[index]= {
          :x => @x_label,
          :y => @in_arr.select {|v| v.to_f >= @lower_bound && v.to_f < @upper_bound}.count
        }
      end
    end
    return @out_arr
  end

  private

  def set_min
    @min = @range = @in_arr.min.to_f
  end

  def set_max
    @max = @in_arr.max.to_f
    @max = @max + @max.abs*0.00000000001
  end

  def set_count
    @count = @in_arr.count
  end

  def set_distribution
    @distribution = sqrt(@count).round
  end

  def set_step
    @step = ((@max-@min)/@distribution)
  end
  
  def refresh_range
    @lower_bound = @range
    @upper_bound = @range+@step
    @range = @upper_bound
  end    
    
  def trunc_range(num)
    return (num*10000000000).to_i/10000000000
  end

  def set_x_label
    if @question.question_type_id == :number
      @x_label = trunc_range(@lower_bound).to_s+' to '+trunc_range(@upper_bound).to_s+' '+@label.to_s
    else
      response_formatter = ReportFormatter.new(@question, @in_arr)
      lower_bound = response_formatter.format_stats(@lower_bound)
      upper_bound = response_formatter.format_stats(@upper_bound)
      @x_label = lower_bound+' to '+upper_bound+' '+@label.to_s
    end 
  end
end
