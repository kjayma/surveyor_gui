require 'stringio'
module SurveyorGui
  module Models
    module QuestionMethods

      def self.included(base)
        base.send :attr_accessor, :dummy_answer, :type, :decimals
        base.send :attr_writer, :answers_textbox, :grid_columns_textbox, :grid_rows_textbox
        base.send :attr_accessible, :dummy_answer, :question_type, :question_type_id, :survey_section_id, :question_group,
                  :text, :text_adjusted_for_group, :pick, :reference_identifier, :display_order, :display_type,
                  :is_mandatory,  :prefix, :suffix, :answers_attributes, :decimals, :dependency_attributes,
                  :hide_label, :dummy_blob, :dynamically_generate, :answers_textbox,
                  :grid_columns_textbox, :grix_rows_textbox,
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

        base.send :validate, :no_responses
        base.send :before_destroy, :no_responses
        base.send :after_save, :process_answers_textbox

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
      
      def text_adjusted_for_group
        if part_of_group?
          question_group.text
        else
          text
        end
      end
      
      def text_adjusted_for_group=(txt)
        @text_adjusted_for_group = txt
      end

      #generates descriptions for different types of questions, including those that use widgets
      def question_type
        @question_type = QuestionTypes.new(self)
      end
      
      def question_type_id
        @question_type ||= QuestionTypes.new(self)
        @question_type.id
      end

      def dynamically_generate
        'false'
      end

      #setter for question type.  Sets both pick and display_type
      def question_type_id=(type)
        case type
        when "pick_one", "grid_one"
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
        when "pick_any", "grid_any"
          write_attribute(:pick, "any")
          prep_picks
          write_attribute(:display_type, "")
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
      end


      #If the question involves picking from a list of choices, this sets response class.
      def prep_picks
        write_attribute(:display_type, self.display_type || "default")
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
          preceding_questions_numbered.count
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
        self.question_group.questions.order('display_order asc').collect(&:text).join("\n")
      end

      def process_answers_textbox
        if !(pick=='none') && !@answers_textbox.nil?
          collection = TextBoxCollection.new(@answers_textbox, answers, Answer, self)
          collection.update_records
        end
      end
   
      def process_grid_rows_textbox
        if (pick=='grid_any' || pick=='grid_one') && !@grid_rows_textbox.nil?
          collection = TextBoxCollection.new(@grid_columns_textbox, answers, Answer, self)
          collection.update_records
        end
      end   
      

      private
      def preceding_questions_numbered
        preceding_questions.delete_if{|p| !p.is_numbered?}
      end

      def preceding_questions
        ##all questions from previous sections, plus all questions with a lower display order than this one
        Question.joins(:survey_section).where(
            '(survey_id = ? and survey_sections.display_order < ?) or (survey_section_id = ? and questions.display_order <= ?)',
            survey_section.survey_id,
            survey_section.display_order,
            survey_section.id,
            display_order
        )
      end
      
      class TextBoxCollection
        def initialize(text, nested_objects, nested_model, parent)
          @text = text.to_s
          @nested_objects = nested_objects
          @nested_model = nested_model
          @parent = parent
        end
        
        def update_records
          _lines.readlines.each_with_index do |line, display_order|
            _update_or_create(line.strip, display_order) unless line.blank?
          end
          _delete_orphans        
        end
        
        private
        
        def _lines
          StringIO.new(@text)
        end
        
        def _update_or_create(line, display_order)
          nested_objects = _find_nested_if_exists(line)
          if nested_objects.empty?
            _create_record(display_order, line)
          else
            _update_display_order(nested_objects.first, display_order)
          end
        end
        
        def _delete_orphans
          valid_rows = @text.split()
          @nested_objects.each do |nested_object|
            nested_object.destroy unless valid_rows.include? "#{nested_object.text.rstrip}"
          end
        end
        
        def _find_nested_if_exists(text)
          @nested_objects.where('text = ?',text)
        end
        
        def _update_display_order(nested_object, index)
          nested_object.update_attributes(:display_order=>index)
        end

        def _create_record(display_order, text)     
          @nested_model.create!(
            "#{@parent.class.name.underscore}_id".to_sym => @parent.id,
            display_order: display_order,
            text: text
          )
        end
      end
      
    end
  end
end

class QuestionTypes
  attr_accessor :id, :text, :all
  def initialize(question)
    _define_question_types
    _categorize_question(question)
  end
  
  private
  def _categorize_question(question)
    if question.part_of_group?
      _categorize_groups(question)
    else
      _categorize_picks(question)
    end
  end
  
  def _categorize_groups(question)
    case question.pick
    when 'one'
      _set_question_type(:grid_one)
    when 'any'
      _set_question_type(:grid_any)
    end
  end
  
  def _categorize_picks(question)
    case question.pick
    when 'one'
      _categorize_pick_one(question)
    when 'any'
      _set_question_type(:pick_any)
    else
      _categorize_no_pick(question)
    end  
  end
  
  def _categorize_pick_one(question)
    case question.display_type 
    when 'slider'
      _set_question_type(:slider)
    when 'stars'
      _set_question_type(:stars)
    when 'dropdown'
      _set_question_type(:dropdown)
    else
      _set_question_type(:pick_one)
    end  
  end
  
  def _categorize_no_pick(question)      
    if question.display_type == 'label'  || !question.answers.first
      _set_question_type(:label)
    else
      case question.answers.first.response_class
      when 'text'
        _set_question_type(:box)
      when 'float', 'integer'
        _set_question_type(:number)
      when 'date'
        _set_question_type(:date)
      when 'blob'
        _set_question_type(:file)
      else
        _set_question_type(:string)
      end
    end
  end  
  
  def _set_question_type(id)
    @id = id
    @text = @all.select{|t| t.id==id}[0].text
  end
  
  def _define_question_types
    type = Struct.new(:id, :text)
    @all = []
    types = [
    [:pick_one,   "Multiple Choice (only one answer)"],
    [:pick_any,   "Multiple Choice (multiple answers)"],    
    [:dropdown,   "Dropdown List"],
    [:string,     "Text"],
    [:number,     "Number"],
    [:date,       "Date"], 
    [:box,        "Text Box (for extended text, like notes, etc.)"],
    [:slider,     "Slider"],
    [:stars,      "1-5 Stars"],
    [:label,      "Label"],
    [:file,       "File Upload"],
    [:grid_one, "Grid (pick one)"],
    [:grid_any, "Grid (pick any)"]
    ]     
    types.map{|t| @all << type.new(t[0], t[1])}
  end
end



