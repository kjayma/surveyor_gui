require 'stringio'
module SurveyorGui
  module Models
    module QuestionMethods

      def self.included(base)
        base.send :attr_accessor, :dummy_answer, :type, :decimals
        base.send :attr_writer, :answers_textbox, :grid_columns_textbox
        base.send :attr_accessible, :dummy_answer, :question_type, :question_type_id, :survey_section_id, :question_group_id,
                  :text, :pick, :reference_identifier, :display_order, :display_type,
                  :is_mandatory,  :prefix, :suffix, :answers_attributes, :decimals, :dependency_attributes,
                  :hide_label, :dummy_blob, :dynamically_generate, :answers_textbox,
                  :grid_columns_textbox, :grid_rows_textbox,
                  :dynamic_source, :modifiable, :report_code if defined? ActiveModel::MassAssignmentSecurity
        base.send :accepts_nested_attributes_for, :answers, :reject_if => lambda { |a| a[:text].blank?}, :allow_destroy => true
        base.send :belongs_to, :survey_section
        base.send :has_many, :responses
        base.send :has_many, :dependency_conditions, :through=>:dependency, :dependent => :destroy
        base.send :default_scope, lambda{ base.order('display_order')}
        base.send :scope, :by_display_order, -> {base.order('display_order')}
        ### everything below this point must be commented out to run the rake tasks.
        base.send :accepts_nested_attributes_for, :dependency, :reject_if => lambda { |d| d[:rule].blank?}, :allow_destroy => true
        base.send :mount_uploader, :dummy_blob, BlobUploader
        base.send :belongs_to, :question_type
        
        base.send :validate, :no_responses
        base.send :before_destroy, :no_responses
        base.send :after_save, :process_answers_textbox
        base.send :after_save, :process_grid_rows_textbox

        base.class_eval do

          def answers_attributes=(ans)
            #don't set answer.text if question_type = number.  In this case, text should get set by the prefix and suffix setters.
            #note: Surveyor uses the answer.text field to store prefix and suffix for numbers.
            #if not a number question, go ahead and set the text attribute as normal.
            if question_type!="Number" && !ans.empty? && ans["0"]
              ans["0"].merge!( {"original_choice"=>ans["0"]["text"]})
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
          self.survey_section.survey.response_sets.where('test_data = ?',true).each {|r| r.destroy}
        end
        if self.id && !survey_section.survey.template && survey_section.survey.response_sets.count>0
          errors.add(:base,"Reponses have already been collected for this survey, therefore it cannot be modified. Please create a new survey instead.")
          return false
        end
      end
      
      def text=(txt)
        write_attribute(:text, txt) 
        if part_of_group?
          question_group.update_attributes(text: txt)
        end
        @text = txt
      end
      
      def grid_rows_textbox=(textbox)
        write_attribute(:text, textbox.match(/.*\r/).to_s.strip)
        @grid_rows_textbox = textbox.gsub(/\r/,"")
      end

      def question_type_id
        QuestionType.categorize_question(self)
      end
      
#      #generates descriptions for different types of questions, including those that use widgets
      def question_type
        @question_type = QuestionType.find(question_type_id)
      end
#      

      def dynamically_generate
        'false'
      end

      #setter for question type.  Sets both pick and display_type
      def question_type_id=(type)
        case type
        when "grid_one"
          write_attribute(:pick, "one")
          prep_picks
          write_attribute(:display_type, "")
          _update_group_id
        when "pick_one"
          write_attribute(:pick, "one")
          prep_picks
          write_attribute(:display_type, "")
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
          write_attribute(:display_type, "")
        when "grid_any"
          write_attribute(:pick, "any")
          prep_picks
          write_attribute(:display_type, "")
          _update_group_id
        when "grid_dropdown"
          write_attribute(:pick, "one")
          prep_picks
          write_attribute(:display_type, "dropdown")
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
          self.answers_attributes={'0'=>{'response_class'=>response_class}}
        else
          self.answers.map{|a|a.response_class=response_class}
        end
      end

      #if the question is not a pick from list of choices (but is a fill in the blank type question) and not multiple choice, this sets it
      #accordingly.
      def prep_not_picks(answer_type)
        write_attribute(:pick, "none")
        write_attribute(:display_type,"default")
        if self.answers.blank?
          #self.answers_attributes={'0'=>{'text'=>'default','response_class'=>answer_type, 'hide_label' => answer_type=='float' ? false : true}}
          self.answers_attributes={'0'=>{'text'=>'default','response_class'=>answer_type, 'display_type' => answer_type=='float' ? 'default' : 'hidden_label'}}
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
        if self.question_type=='Number'
          if self.answers.blank?
            self.answers_attributes={'0'=>{'text'=>pre+'|'}} unless pre.blank?
          else
            if pre.blank?
              self.answers.first.text = 'default'
            else
              self.answers.first.text = pre+'|' unless pre.blank?
            end
          end
        end
      end

      #sets the number suffix
      def suffix=(suf)
        if self.question_type=='Number'
          if self.answers.first.blank? || self.answers.first.text.blank?
            self.answers_attributes={'0'=>{'text'=>'|'+suf}} unless suf.blank?
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
          return "q_hidden"
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
          true
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


      def controlling_questions
        dependencies = []
        dependencies << self.dependency
        dependencies.map{|d| d.dependency_conditions.map{|dc| dc.question}}.flatten.uniq
      end

      def answers_textbox
        self.answers.order('display_order asc').collect(&:text).join("\n")
      end
      
      def grid_columns_textbox
        self.answers.order('display_order asc').collect(&:text).join("\n")
      end
      
      def grid_rows_textbox
        if self.question_group && self.question_group.questions
          self.question_group.questions.order('display_order asc').collect(&:text).join("\n")
        else
          nil
        end
      end

      def process_answers_textbox
        if _pick? && !@answers_textbox.nil? && !_grid?
          updated_answers = TextBoxParser.new(
            textbox: @answers_textbox, 
            records_to_update: answers
          )
          updated_answers.update_or_create_records do |display_order, text|
            _create_an_answer(display_order, text, self)     
          end
        end
      end
   
      def process_grid_rows_textbox
        #puts "processing grid rows \ntextbox grid?: #{_grid?} \ntb: #{@grid_rows_textbox} \nthis: #{self.id}\ntext: #{self.text}"
        if _grid? && !@grid_rows_textbox.nil?
          #puts 'got to inner if'
          #puts "\n\n#{self.display_order}\n\n"
          display_order_of_first_question_in_group = self.display_order
          #_create_some_answers(self)
          grid_rows = TextBoxParser.new(
            textbox: @grid_rows_textbox, 
            records_to_update: @question_group.questions,
            starting_display_order: display_order_of_first_question_in_group            
          )
          grid_rows.update_or_create_records(pick: self.pick) do |display_order, new_text|
            current_question = _create_a_question(display_order, new_text) 
            #puts "current question: #{current_question.text} #{current_question.question_group_id} saved? #{current_question.persisted?} id: #{current_question.id}"
            #_create_some_answers(current_question)
          end
          @question_group.questions.each do |question|
            _create_some_answers(question)
          end
          #work around for infernal :dependent=>:destroy on belongs_to :question_group from Surveyor
          #can't seem to override it and everytime a question is deleted, the whole group goes with it.
          #which makes it impossible to delete a question from a grid.
          #puts "\n\n\nTrying to keep me damn groups "
          begin
            QuestionGroup.find(@question_group)
          rescue
            QuestionGroup.create!(@question_group.attributes)
          end
        end
      end

      private
      
      def _update_group_id
        @question_group = self.question_group || 
          QuestionGroup.create!(text: @text, display_type: :grid)
        self.question_group_id = @question_group.id
      end
      
      def _pick?
        !(pick=="none")
      end
      
      def _grid?
        ["grid_one", "grid_any", "grid_dropdown"].include? @question_type_id
      end
      
      
      def _create_an_answer(display_order, new_text, current_question)  
        Answer.create!(
          question_id: current_question.id,
          display_order: display_order,
          text: new_text
        )
      end
      
      def _create_a_question(display_order, new_text) 
        #puts "making question #{new_text}" 
          #puts "\n\n#{self.display_order}\n\n"
        if !@question_group.questions.collect(&:text).include? new_text
          Question.create!(
            display_order: (display_order - 1),
            text: new_text,
            survey_section_id: survey_section_id,
            question_group_id: @question_group.id,
            pick: pick,
            reference_identifier: reference_identifier,
            display_type: display_type,
            is_mandatory: is_mandatory,
            prefix: prefix, 
            suffix: suffix,
            decimals: decimals,
            modifiable: modifiable,
            report_code: report_code          
          )
        end
      end
      
      def _create_some_answers(current_question)        
        if @grid_columns_textbox.nil?
          @grid_columns_textbox = " "
        end
        columns = TextBoxParser.new(
          textbox: @grid_columns_textbox, 
          records_to_update: current_question.answers
        )
        columns.update_or_create_records do |display_order, text|
          _create_an_answer(display_order, text, current_question) 
        end
        
      end
      
      def _preceding_questions_numbered
        _preceding_questions.delete_if{|p| !p.is_numbered?}
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

class TextBoxParser
  include Enumerable
  def initialize(args)
    @text = args[:textbox].to_s.gsub("\r","")
    @nested_objects = args[:records_to_update]
    @starting_display_order = args.fetch(:starting_display_order,0) 
  end
  
  def each(&block)
    _lines.readlines.each(&block)
  end
  
  def update_or_create_records(update_params={}, &create_object)
    _lines.readlines.each_with_index do |line, display_order|
      _update_or_create(
        line.strip, 
        display_order + @starting_display_order, 
        update_params, 
        &create_object
      ) unless line.blank?
    end
    _delete_orphans        
  end
  
  private
  
  def _lines
    StringIO.new(@text)
  end
  
  def _update_or_create(text, display_order, update_params={}, &create_object)
    nested_objects = _find_nested_if_exists(text)
    if nested_objects.empty?
      create_object.call(display_order, text) 
    else
      _update_nested_object(nested_objects.first, display_order, update_params)
    end
  end
  
  def _delete_orphans
    valid_rows = @text.split("\n")
    valid_rows = valid_rows.map{|vr| vr.strip}
    @nested_objects.reload
    @nested_objects.each do |nested_object|
      #puts "possibly deleting #{nested_object.class.name} #{nested_object.id} #{nested_object.text.rstrip} valid #{valid_rows}"
      nested_object.destroy unless valid_rows.include? "#{nested_object.text.rstrip}"
    end
    _dedupe
  end
  
  def _find_nested_if_exists(text)
    @nested_objects.where('text = ?',text)
  end
  
  def _update_nested_object(nested_object, index, update_params)
    params = {:display_order=>index}.merge(update_params)
    nested_object.update_attributes(params)
  end
  
  def _dedupe
    grouped = @nested_objects.order('display_order DESC').group(:text).collect(&:id)
    @nested_objects.each do |obj|
      obj.destroy unless (grouped.include? obj.id)
    end
  end  

end





