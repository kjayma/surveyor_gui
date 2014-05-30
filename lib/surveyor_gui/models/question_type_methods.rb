module SurveyorGui
  module Models
    module QuestionTypeMethods

      attr_accessor :id, :text, :part_of_group, :pick, :display_type, :group_display_type

      def initialize(args)
        @id                 = args[:id]
        @text               = args[:text]
        @part_of_group      = args[:part_of_group]
        @pick               = args[:pick]
        @display_type       = args[:display_type]
        @group_display_type = args[:group_display_type]
        
      end

      def self.included(base)
        base.send :extend, ClassMethods
      end
      
      def persisted?
        false
      end
      
      def grid?
        @id == :grid_one || @id == :grid_any
      end
      
      def build_complex_question_structure(question, args)
        #looks at id and calls the appropriate methods, eg.
        #if question_type.id is pick_one, calls _build_pick_one
        question.reload
        puts question.attributes
        builder = "_build_"+id.to_s
        send builder.to_sym, question, args
      end
       
      private 
      
      def _build_pick_one(question, args)
        _process_answers_textbox(question, args)
      end 
      
      def _build_pick_any(question, args)
        _process_answers_textbox(question, args)
      end  
      
      def _build_slider(question, args)
        _process_answers_textbox(question, args)
      end
       
      def _build_dropdown(question, args)
        _process_answers_textbox(question, args)
      end 
      
      def _build_grid_one(question, args)
        _build_grid(question,args)
      end
      
      def _build_grid_any(question, args)
        _build_grid(question,args)
      end
      
      def _build_grid_dropdown(question, args)
        _build_grid(question,args)     
      end
      
      def _build_grid(question,args)
        grid_columns_textbox  = args[:grid_columns_textbox]
        grid_rows_textbox     = args[:grid_rows_textbox]
        _process_grid_rows_textbox(question, grid_columns_textbox, grid_rows_textbox)
      end

      def _process_answers_textbox(question, args)
        answers_textbox  = args[:answers_textbox]
        updated_answers = TextBoxParser.new(
          textbox: answers_textbox, 
          records_to_update: question.answers
        )
        updated_answers.update_or_create_records do |display_order, text|
          _create_an_answer(display_order, text, question)     
        end
      end
   
      def _process_grid_rows_textbox(question, grid_columns_textbox, grid_rows_textbox)
        #puts "processing grid rows \ntextbox grid?: #{_grid?(question)} \ntb: #{grid_rows_textbox} \ntb: #{grid_columns_textbox}\nthis: #{question.id}\ntext: #{question.text}"
        #puts 'got to inner if'
        #puts "\n\n#{question.display_order}\n\n"
        display_order_of_first_question_in_group = question.display_order
        grid_rows = TextBoxParser.new(
          textbox: grid_rows_textbox, 
          records_to_update: question.question_group.questions,
          starting_display_order: display_order_of_first_question_in_group            
        )
        grid_rows.update_or_create_records(pick: question.pick, display_type: question.display_type) \
         do |display_order, new_text|
          current_question = _create_a_question(question, display_order, new_text) 
          #puts "current question: #{current_question.text} #{current_question.question_group_id} saved? #{current_question.persisted?} id: #{current_question.id}"
        end
        question.question_group.questions.each do |question|
          _create_some_answers(question, grid_columns_textbox)
        end
        #work around for infernal :dependent=>:destroy on belongs_to :question_group from Surveyor
        #can't seem to override it and everytime a question is deleted, the whole group goes with it.
        #which makes it impossible to delete a question from a grid.
        begin
          QuestionGroup.find(question.question_group)
        rescue
          QuestionGroup.create!(question.question_group.attributes)
        end
      end
        
      def _pick?
        !(pick=="none")
      end
      
      def _grid?(question)
        [:grid_one, :grid_any, :grid_dropdown].include? self.id
      end
      
      def _create_some_answers(current_question, grid_columns_textbox)       
        if grid_columns_textbox.nil?
          grid_columns_textbox = " "
        end
        columns = TextBoxParser.new(
          textbox: grid_columns_textbox, 
          records_to_update: current_question.answers
        )
        columns.update_or_create_records do |display_order, text|
          _create_an_answer(display_order, text, current_question) 
        end
        
      end
      
      
      def _create_an_answer(display_order, new_text, current_question)  
        Answer.create!(
          question_id: current_question.id,
          display_order: display_order,
          text: new_text
        )
      end
      
      def _create_a_question(question, display_order, new_text) 
        #puts "making question #{new_text}" 
        #puts "\n\n#{self.display_order}\n\n"
        if !question.question_group.questions.collect(&:text).include? new_text
          Question.create!(
            display_order:        (display_order - 1),
            text:                 new_text,
            survey_section_id:    question.survey_section_id,
            question_group_id:    question.question_group.id,
            pick:                 question.pick,
            reference_identifier: question.reference_identifier,
            display_type:         question.display_type,
            is_mandatory:         question.is_mandatory,
            prefix:               question.prefix, 
            suffix:               question.suffix,
            decimals:             question.decimals,
            modifiable:           question.modifiable,
            report_code:          question.report_code          
          )
        end
      end
        
      
#----------------------------- end instance methods ---------------------------------------------------------------      
      module ClassMethods

      AllTypes = [
          #                                                                                             group
          #                                                                   part_of_         display  display
          #id               #text                                             group?    pick   type     type     
          [:pick_one,       "Multiple Choice (only one answer)"               , false,  :one,  "default", nil      ],
          [:pick_any,       "Multiple Choice (multiple answers)"              , false,  :any,  "default", nil      ],  
          [:box,            "Text Box (for extended text, like notes, etc.)"  , false,  :none, :text,     nil      ],  
          [:dropdown,       "Dropdown List"                                   , false,  :one,  :dropdown, nil      ],
          [:string,         "Text"                                            , false,  :none, :default,  nil      ],
          [:number,         "Number"                                          , false,  :none, :float,    nil      ],
          [:number,         "Number"                                          , false,  :none, :integer,  nil      ],
          [:date,           "Date"                                            , false,  :none, :date,     nil      ], 
          [:slider,         "Slider"                                          , false,  :one,  :slider,   nil      ],
          [:stars,          "1-5 Stars"                                       , false,  :one,  :stars,    nil      ],
          [:label,          "Label"                                           , false,  :none, :label,    nil      ],
          [:file,           "File Upload"                                     , false,  :none, :file,     nil      ],
          [:grid_one,       "Grid (pick one)"                                 , true,   :one,  "default", :grid    ],
          [:grid_any,       "Grid (pick any)"                                 , true,   :any,  "default", :grid    ],
          [:grid_dropdown,  "Group of Dropdowns"                              , true,   :one,  :dropdown, :grid    ],
          [:group_inline,   "Inline Question Group"                           , true,   nil,   nil,       :inline  ],
          #nothing below here shows up on the question builder choices for question type
          [:pick_one,       "Multiple Choice (only one answer)"               , true,   :one,  "default", :inline  ],
          [:pick_any,       "Multiple Choice (multiple answers)"              , true,   :any,  "default", :inline  ],  
          [:box,            "Text Box (for extended text, like notes, etc.)"  , true,   :none, :text,     :inline  ],  
          [:dropdown,       "Dropdown List"                                   , true,   :one,  :dropdown, :inline  ],
          [:string,         "Text"                                            , true,   :none, :default,  :inline  ],
          [:number,         "Number"                                          , true,   :none, :float,    :inline  ],
          [:number,         "Number"                                          , true,   :none, :integer,  :inline  ],
          [:date,           "Date"                                            , true,   :none, :date,     :inline  ], 
          [:slider,         "Slider"                                          , true,   :one,  :slider,   :inline  ],
          [:stars,          "1-5 Stars"                                       , true,   :one,  :stars,    :inline  ],
          [:label,          "Label"                                           , true,   :none, :label,    :inline  ],
          [:file,           "File Upload"                                     , true,   :none, :file,     :inline  ],
          [:repeater,       "Repeater (add as many answers as apply"          , true,   :all,  :all,      :repeater],
          #surveyor seems to have an inline option that doesn't actually render inline yet.  Recognize it
          #but don't treat it differently.  See question 16 and 17 in kitchen_sink_survey.rb. 
          [:pick_one,       "Multiple Choice (only one answer)"               , false,  :one,  "inline",  nil    ],
          [:pick_any,       "Multiple Choice (multiple answers)"              , false,  :any,  "inline",  nil    ],
       ]      

            
        def categorize_question(question)
          all.each do |question_type|
            return question_type.id if _match_found(question, question_type)
          end
          raise "No question_type matches question #{question.id}"
        end
        
        def all
          arr = []
          type = Struct.new(:id, :text, :part_of_group, :pick, :display_type, :group_display_type)
          AllTypes.each do |t|
            arr << QuestionType.new(id:                 t[0], 
                                    text:               t[1], 
                                    part_of_group:      t[2],
                                    pick:               t[3],
                                    display_type:       t[4],
                                    group_display_type: t[5]
                                    )  
          end
          arr
        end
        
        def find(id)
          all.select{|qt| qt.id == id}[0]
        end
          
        private
        
        def _match_found(question, question_type)
          question_group_display_type = question.part_of_group? ? question.question_group.display_type : ""
          
          _match(question.part_of_group?,     question_type.part_of_group, :part_of_group)          &&
          _match(question.pick,               question_type.pick.to_s, :pick)                       &&
          _match(question.display_type.to_s,  question_type.display_type.to_s, :display_type)       &&
          _match(question_group_display_type, question_type.group_display_type.to_s, :group_display_type)         
        end
      
        def _match(question_attribute, question_type_attribute, match_attribute)
          (question_attribute == question_type_attribute) || 
          (question_type_attribute == "all")  
        end      
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

