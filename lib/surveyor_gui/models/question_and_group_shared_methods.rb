module SurveyorGui

  module Models

    module QuestionAndGroupSharedMethods


      def controlling_questions

        dependencies = []
        dependencies << self.dependency
        dependencies.map { |d| d.dependency_conditions.map { |dc| dc.question.part_of_group? ? dc.question.question_group.questions.last : dc.question } }.flatten.uniq

      end


    end

  end
end
