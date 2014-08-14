module SurveyorGui::ReportHelper

  def question_should_display(q)
    display=true
    if q.dependency
      q.dependency.dependency_conditions.each do |dc|
        if Response.where(:question_id => dc.question_id).first && dc.answer_id != Response.where(:question_id => dc.question_id).first.answer_id
          display=false
        end
      end
    end
    return display
  end
  
  def star_average(responses,q)
    (responses.where(:question_id => q.id).where('integer_value > ?',0).collect(&:integer_value).average * 2).round
  end

end
