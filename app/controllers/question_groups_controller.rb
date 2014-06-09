def create
  @question_group = QuestionGroup.new(question_group_params)
  if @question_group.save
    render :inline => '<div id="cboxQuestionId">'+@question.id.to_s+'</div>', :layout=>'colorbox'
  else
    @title = "Add Question"
    redirect_to :action => 'new', :controller => 'questions', :layout=>'colorbox'
  end
end
