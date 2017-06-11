require 'stringio'

module SurveyorGui

  module Models

    module QuestionMethods

      include QuestionAndGroupSharedMethods


      def self.included(base)

        base.send :attr_accessor, :dummy_answer, :dummy_answer_array, :type, :decimals

        base.send :attr_writer, :grid_columns_textbox, :omit, :omit_text,
                  :other, :other_text, :comments_text, :comments, :dropdown_column_count


        if defined? ActiveModel::MassAssignmentSecurity
          base.send :attr_accessible, :dummy_answer, :dummy_answer_array, :question_type, :question_type_id, :survey_section_id, :question_group_id,
                    :text, :pick, :reference_identifier, :display_order, :display_type,
                    :is_mandatory, :prefix, :suffix, :answers_attributes, :decimals, :dependency_attributes,
                    :hide_label, :dummy_blob, :dynamically_generate, :answers_textbox, :dropdown_column_count,
                    :grid_columns_textbox, :grid_rows_textbox, :omit_text, :omit, :other, :other_text, :is_comment, :comments, :comments_text,
                    :dynamic_source, :modifiable, :report_code, :question_group_attributes
        end

        base.send :accepts_nested_attributes_for, :answers, :reject_if => lambda { |a| a[:text].blank? }, :allow_destroy => true

        base.send :belongs_to, :survey_section

        base.send :has_many, :responses

        base.send :has_many, :dependency_conditions, :through => :dependency, :dependent => :destroy

        base.send(:default_scope, lambda { base.order('display_order') })

        base.send(:scope, :by_display_order, -> { base.order('display_order') })


        ### everything below this point must be commented out to run the rake tasks.

        base.send :accepts_nested_attributes_for, :dependency, :reject_if => lambda { |d| d[:rule].blank? }, :allow_destroy => true

        base.send :mount_uploader, :dummy_blob, BlobUploader

        base.send :belongs_to, :question_type

        base.send :validate, :no_responses


        base.send :before_destroy, :no_responses

        base.send :after_save, :build_complex_questions

        base.send :before_save, :make_room_for_question

        base.send( :scope, :is_not_comment, -> { base.where(is_comment: false) } )
        base.send( :scope, :is_comment, -> { base.where(is_comment: true) } )

        base.send( :scope, :in_response_set, ->(resp_set) { base.includes(:responses).joins(:responses).where('responses.response_set_id = ?', resp_set.id ) })


        base.class_eval do

          def answers_attributes=(ans)

            # don't set answer.text if question_type = number.  In this case,
            # text should get set by the prefix and suffix setters.
            # Note: Surveyor uses the answer.text field to store prefix and suffix for numbers.
            #  If not a number question, go ahead and set the text attribute as normal.
            #
            if @question_type_id!='number' && !ans.empty? && ans["0"]
              ans["0"].merge!({ 'original_choice' => ans["0"]["text"] })

              assign_nested_attributes_for_collection_association(:answers, ans)
            end
          end

        end

      end


      def default_args
        self.is_mandatory ||= false
        self.display_type ||= "default"
        self.pick ||= "none"
        self.data_export_identifier ||= Surveyor::Common.normalize(text)
        self.short_text ||= text
        self.api_id ||= Surveyor::Common.generate_api_id
      end


      #prevent a question from being modified if responses have been submitted for the survey. Protects data integrity.
      def no_responses

        #below is code to fix a bizarre bug. When triggered by the "cut" function, for some reason survey_id is erased. Have not found reason yet. Temporary fix.
        if !survey_section && self.id
          self.reload
        end

        if self.id && self.survey_section && self.survey_section.survey
          #this will be a problem if two people are editing the survey at the same time and do a survey preview - highly unlikely though.
          self.survey_section.survey.response_sets.where('test_data = ?', true).each { |r| r.destroy }
        end

        if self.id && !survey_section.survey.template && survey_section.survey.response_sets.count > 0
          errors.add(:base, "Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
          false
        end
      end


      def dynamically_generate
        'false'
      end


      def question_type_id
        QuestionType.categorize_question(self)
      end


      # generates descriptions for different types of questions, including those that use widgets
      def question_type
        @question_type = QuestionType.find(question_type_id)
      end


      #

      #setter for question type.  Sets both pick and display_type
      def question_type_id=(type)
        case type
          when "grid_one"
            write_attribute(:pick, "one")
            prep_picks
            write_attribute(:display_type, "default")
            _update_group_id
          when "pick_one"
            write_attribute(:pick, "one")
            prep_picks
            write_attribute(:display_type, "default")
            _remove_group
          when "slider"
            write_attribute(:pick, "one")
            prep_picks
            write_attribute(:display_type, "slider")
          when "stars"
            write_attribute(:pick, "one")
            write_attribute(:display_type, "stars")
            prep_picks
          when "dropdown"
            write_attribute(:pick, "one")
            write_attribute(:display_type, "dropdown")
            prep_picks
          when "pick_any"
            write_attribute(:pick, "any")
            prep_picks
            write_attribute(:display_type, "default")
            _remove_group
          when "grid_any"
            write_attribute(:pick, "any")
            prep_picks
            write_attribute(:display_type, "default")
            _update_group_id
          when "grid_dropdown"
            write_attribute(:pick, "one")
            prep_picks
            write_attribute(:display_type, "dropdown")
            _update_group_id
          when "group_inline"
            _update_group_id
          when 'label'
            write_attribute(:pick, "none")
            write_attribute(:display_type, "label")
          when 'box'
            prep_not_picks('text')
          when 'number'
            prep_not_picks('float')
          when 'date'
            prep_not_picks('date')
          when 'time'
            prep_not_picks('time')
          when 'datetime'
            prep_not_picks('datetime')
          when 'file'
            prep_not_picks('blob')
          when 'string'
            prep_not_picks('string')
        end
        @question_type_id = type
      end


      #If the question involves picking from a list of choices, this sets response class.
      def prep_picks
        #write_attribute(:display_type, self.display_type || "default")
        if self.display_type=='stars'
          response_class='integer'
        else
          response_class='answer'
        end
        if self.answers.blank?
          self.answers_attributes={ '0' => { 'text' => 'default', 'response_class' => response_class } }
        else
          self.answers.map { |a| a.response_class=response_class }
        end
      end


      #if the question is not a pick from list of choices (but is a fill in the blank type question) and not multiple choice, this sets it
      #accordingly.
      def prep_not_picks(answer_type)
        write_attribute(:pick, "none")
        write_attribute(:display_type, "default")
        if self.answers.blank?
          #self.answers_attributes={'0'=>{'text'=>'default','response_class'=>answer_type, 'hide_label' => answer_type=='float' ? false : true}}
          self.answers_attributes={ '0' => { 'text' => 'default', 'response_class' => answer_type, 'display_type' => answer_type=='float' ? 'default' : 'hidden_label' } }
        else
          self.answers.first.response_class=answer_type
          #self.answers.first.hide_label = answer_type=='float' ? false : true
          self.answers.first.display_type = answer_type=='float' ? 'default' : 'hidden_label'
        end
      end


      #number prefix getter.  splits a number question into the actual answer and it's unit type. Eg, you might want a
      #number to be prefixed with a dollar sign.
      def prefix
        if self.answers.first && self.answers.first.text.include?('|')
          self.answers.first.text.split('|')[0]
        end
      end


      #number suffix getter. sometimes you want a number question to have a units of measure suffix, like "per day"
      def suffix
        if self.answers.first && self.answers.first.text.include?('|')
          self.answers.first.text.split('|')[1]
        end
      end


      #sets the number prefix
      def prefix=(pre)
        if @question_type_id=="number"
          if self.answers.blank?
            self.answers_attributes={ '0' => { 'text' => pre+'|' } } unless pre.blank?
          else
            if pre.blank?
              self.answers.first.text = 'default'
            else
              self.answers.first.text = pre+'|'
            end
          end
        end
      end


      #sets the number suffix
      def suffix=(suf)
        if @question_type_id=="number"
          if self.answers.first.blank? || self.answers.first.text.blank?
            self.answers_attributes={ '0' => { 'text' => '|'+suf } } unless suf.blank?
          else
            if self.answers.first.text=='default'
              self.answers.first.text='|'+suf
            elsif self.answers.first.text.blank?
              self.answers.first.text = '|'+suf
            else
              self.answers.first.text=self.answers.first.text+suf
            end
          end
        end
      end


      def surveyresponse_class(response_sets)
        if dependent?
          response_sets.each do |r|
            if triggered?(r)
              return nil
            end
          end
          "q_hidden"

        else
          nil
        end
      end


      def question_description
        ## this is an expensive method - use sparingly
        is_numbered? ? question_number.to_s + ') ' + text : text
      end


      def is_numbered?
        case display_type
          when 'label'
            false
          else
            if part_of_group?
              if question_group.questions.last.id == self.id
                true
              else
                false
              end
            else
              true
            end
        end
      end


      def question_number
        ##this is an expensive method - use sparingly
        ##should consider adding question_number attribute to table in future
        if survey_section.id.nil?
          nil
        else
          _preceding_questions_numbered.count
        end
      end


      #def controlling_questions in QuestionAndGroupSharedMethods

      def answers_textbox
        self.answers.where('is_exclusive != ? and is_comment != ? and response_class != ?', true, true, "string").order('display_order asc').collect(&:text).join("\n")
      end


      def answers_textbox=(textbox)
        #change updated_at as a hack to force dirty record for change on answers_textbox
        write_attribute(:updated_at, Time.now)
        @answers_textbox=textbox
      end


      def omit
        @omit = self.answers.where('is_exclusive = ?', true).size > 0
      end


      def omit_text
        answer = self.answers.where('is_exclusive = ?', true).first
        @omit_text = (answer ? answer.text : "none of the above")
      end


      def other
        @other = self.answers.where('response_class = ? and is_exclusive = ? and is_comment = ?', "string", false, false).size > 0
      end


      def other_text
        answer = self.answers.where('response_class = ? and is_exclusive = ? and is_comment = ?', "string", false, false).first
        @other_text = (answer ? answer.text : "Other")
      end


      def comments
        if self.part_of_group?
          @comments = self.question_group.questions.where('is_comment=?', true).size > 0
        else
          @comments = self.answers.where('is_comment=?', true).size > 0
        end
      end


      def comments_text
        if self.part_of_group?
          @comments_text = is_comment ? self.answers.first.text : "Comments"
        else
          answer = self.answers.where('is_comment=?', true).first
          @comments_text = (answer ? answer.text : "Comments")
        end
      end


      def dropdown_column_count
        @dropdown_column_count = @dropdown_column_count || (self.question_group ? self.question_group.columns.size : 1)
      end


      def grid_columns_textbox
        self.answers.where('response_class != ? and is_exclusive = ?', "string", false).order('display_order asc').collect(&:text).join("\n")
      end


      def grid_rows_textbox
        if self.question_group && self.question_group.questions
          self.question_group.questions.where('is_comment=?', false).order('display_order asc').collect(&:text).join("\n")
        else
          nil
        end
      end


      def question_group_attributes=(params)
        if question_group
          question_group.update_attributes(params.except(:id))
          @question_group_attributes=params
        else
          QuestionGroup.create!(params)
        end
      end


      def text=(txt)
        write_attribute(:text, txt)
        if part_of_group? && question_group.display_type != "inline"
          question_group.update_attributes(text: txt)
        end
        @text = txt
      end


      def grid_rows_textbox=(textbox)
        write_attribute(:text, textbox.match(/.*\r*/).to_s.strip)
        @grid_rows_textbox = textbox.gsub(/\r/, "")
      end


      def build_complex_questions

        if (@answers_textbox && self.pick!="none") || @grid_columns_textbox || @grid_rows_textbox

          self.question_type.build_complex_question_structure(
              self,
              answers_textbox: @answers_textbox,
              omit_text: @omit_text,
              is_exclusive: @omit == "1",
              other_text: @other_text,
              other: @other == "1",
              comments_text: @comments_text,
              comments: @comments == "1",
              grid_columns_textbox: @grid_columns_textbox,
              grid_rows_textbox: @grid_rows_textbox)
        end

      end


      def next_display_order
        if part_of_group?
          self.question_group.questions.last.display_order + 1
        else
          display_order + 1
        end
      end


      def make_room_for_question
        if new_record?
          if Question.where('survey_section_id = ? and display_order = ?', survey_section_id, display_order).size > 0
            Question.where(:survey_section_id => survey_section_id)
                .where("display_order >= ?", display_order)
                .update_all("display_order = display_order+1")
          end
        end
      end


      def repeater?
        part_of_group? ? (question_group.display_type=="repeater" ? true : false) : false
      end


      private

      def _update_group_id
        @question_group = @question_group || self.question_group ||
            QuestionGroup.create!(text: @text, display_type: :grid)
        self.question_group_id = @question_group.id
      end


      def _remove_group
        if part_of_group?
          question_group.questions.map { |q| q.destroy if q.id != id }
          write_attribute(:question_group_id, nil)
        end
      end


      def _preceding_questions_numbered
        _preceding_questions.to_a.delete_if { |p| !p.is_numbered? }
      end


      def _preceding_questions
        ##all questions from previous sections, plus all questions with a lower display order than this one
        Question.joins(:survey_section).where(
            '(survey_id = ? and survey_sections.display_order < ?) or (survey_section_id = ? and questions.display_order <= ?)',
            survey_section.survey_id,
            survey_section.display_order,
            survey_section.id,
            display_order
        )
      end
    end
  end
end
