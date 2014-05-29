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
      
      module ClassMethods

      AllTypes = [
          #                                                                                             group
          #                                                                   part_of_         display  display
          #id               #text                                             group?    pick   type     type     
          [:pick_one,       "Multiple Choice (only one answer)"               , false,  :one,  "default", nil    ],
          [:pick_any,       "Multiple Choice (multiple answers)"              , false,  :any,  "default", nil    ],  
          [:box,            "Text Box (for extended text, like notes, etc.)"  , false,  :none, :text,     nil    ],  
          [:dropdown,       "Dropdown List"                                   , false,  :one,  :dropdown, nil    ],
          [:string,         "Text"                                            , false,  :none, :default,  nil    ],
          [:number,         "Number"                                          , false,  :none, :float,    nil    ],
          [:number,         "Number"                                          , false,  :none, :integer,  nil    ],
          [:date,           "Date"                                            , false,  :none, :date,     nil    ], 
          [:slider,         "Slider"                                          , false,  :one,  :slider,   nil    ],
          [:stars,          "1-5 Stars"                                       , false,  :one,  :stars,    nil    ],
          [:label,          "Label"                                           , false,  :none, :label,    nil    ],
          [:file,           "File Upload"                                     , false,  :none, :file,     nil    ],
          [:grid_one,       "Grid (pick one)"                                 , true,   :one,  "default", :grid  ],
          [:grid_any,       "Grid (pick any)"                                 , true,   :any,  "default", :grid  ],
          [:grid_dropdown,  "Group of Dropdowns"                              , true,   :one,  :dropdown, :grid  ],
          [:group_inline,   "Inline Question Group"                           , true,   :all,  :all,      :inline],
          [:group_inline,   "Inline Question Group"                           , true,   :all,  :all,      :inline],
          [:repeater,       "Repeater (add as many answers as apply"          , true,   :all,  :all,      :repeater],
          #surveyor seems to have an inline option that doesn't actually render inline yet.  Recognize it
          #but don't treat it differently.  See question 16 and 17 in kitchen_sink_survey.rb. 
          [:pick_one,       "Multiple Choice (only one answer)"               , false,  :one,  "inline",  nil    ],
          [:pick_any,       "Multiple Choice (multiple answers)"              , false,  :any,  "inline",  nil    ],
       ]      

            
        def categorize_question(question)
          $stdout.sync = true
          all.each do |question_type|
            print "\t\t#{question_type.id}\n\t\t"
            return question_type.id if _match_found(question, question_type)
            puts
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
          print "\t#{match_attribute} #{
          (question_attribute == question_type_attribute) || 
          (question_type_attribute == :all)  }"
          (question_attribute == question_type_attribute) || 
          (question_type_attribute == "all")  
        end       
      end
    end
      
  end
end
