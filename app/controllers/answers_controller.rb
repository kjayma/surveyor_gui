class AnswersController < ApplicationController
  def sort
    question = Question.find(params[:question_id])
    aatts={:id=>params[:question_id], :answers_attributes=>{}}
    answers = params[:answer]
    answers.each_with_index do |aid, index|
      aatts[:answers_attributes][index.to_s]={:id => aid,:display_order => index+1, :text=>question.answers.where(:id=>aid.to_s).first.text}
    end
    question.update_attributes!(aatts)
    question.answers.first.update_attribute(:original_choice,question.answers.first.text)
    render :nothing => true
  end
end
