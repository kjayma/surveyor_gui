module SurveyorGui
  module Models
    module QuestionMethods

      def self.included(base)
        base.send :attr_accessor, :dummy_answer, :type, :decimals
        base.send :attr_accessible, :dummy_answer, :question_type, :survey_section_id, :question_group,
                  :text, :pick, :reference_identifier, :display_order, :display_type,
                  :is_mandatory,  :prefix, :suffix, :answers_attributes, :decimals, :dependency_attributes,
                  :hide_label, :dummy_blob, :dynamically_generate,
                  :dynamic_source, :modifiable, :report_code
        base.send :accepts_nested_attributes_for, :answers, :reject_if => lambda { |a| a[:text].blank?}, :allow_destroy => true
        base.send :belongs_to, :survey_section
        base.send :has_many, :responses
        base.send :has_many, :dependency_conditions, :through=>:dependency, :dependent => :destroy
        base.send :default_scope, :order => 'display_order'
        base.send :scope, :by_display_order, :order => 'display_order'
        ### everything below this point must be commented out to run the rake tasks.
        base.send :accepts_nested_attributes_for, :dependency, :reject_if => lambda { |d| d[:rule].blank?}, :allow_destroy => true
        base.send :mount_uploader, :dummy_blob, BlobUploader

        base.send :validate, :no_responses
        base.send :before_destroy, :no_responses

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

      #generates descriptions for different types of questions, including those that use widgets
      def question_type
        if self.pick == 'one'
          if self.display_type == 'slider'
            "Slider"
          elsif self.display_type == 'stars'
            "1-5 Stars"
          elsif self.display_type == 'dropdown'
            "Dropdown List"
          else
            "Multiple Choice (only one answer)"
          end
        elsif self.pick == 'any'
          "Multiple Choice (multiple answers)"
        else
          if self.display_type == 'label'  || !self.answers.first
            "Label"
          elsif self.answers.first.response_class == 'text'
            "Text Box (for extended text, like notes, etc.)"
          elsif self.answers.first.response_class == 'float' || self.answers.first.response_class == 'integer'
            "Number"
          elsif self.answers.first.response_class == 'date'
            "Date"
          elsif self.answers.first.response_class == 'blob'
            "File Upload"
          else
            "Text"
          end
        end
      end

      def text=(t1)
        write_attribute(:text, t1.match(/[\w\s\(\)\[\]\-\\\,\.\?\+\**&^%$#\@!%^-{}|:;'"<>\/\n\r\t~`]+/).to_s)
      end

      def dynamically_generate
        'false'
      end

      #setter for question type.  Sets both pick and display_type
      def question_type=(type)
        case type
        when "Multiple Choice (only one answer)"
          write_attribute(:pick, "one")
          prep_picks
          write_attribute(:display_type, "")
        when "Slider"
          write_attribute(:pick, "one")
          prep_picks
          write_attribute(:display_type, "slider")
        when "1-5 Stars"
          write_attribute(:pick, "one")
          write_attribute(:display_type, "stars")
          prep_picks
        when "Dropdown List"
          write_attribute(:pick, "one")
          write_attribute(:display_type, "dropdown")
          prep_picks
        when "Multiple Choice (multiple answers)"
          write_attribute(:pick, "any")
          prep_picks
          write_attribute(:display_type, "")
        when 'Label'
          write_attribute(:pick, "none")
          write_attribute(:display_type, "label")
        when 'Text Box (for extended text, like notes, etc.)'
          prep_not_picks('text')
        when 'Number'
          prep_not_picks('float')
        when 'Date'
          prep_not_picks('date')
        when 'File Upload'
          prep_not_picks('blob')
        when 'Text'
          prep_not_picks('string')
        end
      end

#      #setter for pick
#      def pick=(val)
#        if self.pick
#          write_attribute(:pick, self.pick)
#        else
#          write_attribute(:pick, val.nil? ? nil : val.to_s)
#        end
#      end
#
#      #setter for display_type
#      def display_type=(val)
#        if self.display_type
#          write_attribute(:display_type, self.display_type.nil? ? nil : self.display_type.to_s)
#        else
#          write_attribute(:display_type, val.nil? ? nil : val.to_s)
#        end
#      end

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
    end
  end
end
