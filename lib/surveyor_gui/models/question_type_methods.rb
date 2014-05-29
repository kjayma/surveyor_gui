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
          [:pick_one,       "Multiple Choice (only one answer)"               , false,  :one,  nil,       nil    ],
          [:pick_any,       "Multiple Choice (multiple answers)"              , false,  :any,  nil,       nil    ],  
          [:box,            "Text Box (for extended text, like notes, etc.)"  , false,  :none, :text,     nil    ],  
          [:dropdown,       "Dropdown List"                                   , false,  :one,  :dropdown, nil    ],
          [:string,         "Text"                                            , false,  :none, :default,  nil    ],
          [:number,         "Number"                                          , false,  :none, :float,    nil    ],
          [:number,         "Number"                                          , false,  :none, :integer,  nil    ],
          [:date,           "Date"                                            , false,  :none, :date,     nil    ], 
          [:slider,         "Slider"                                          , false,  :one,  :slider,   nil    ],
          [:stars,          "1-5 Stars"                                       , false,  :one,  :stars,    nil    ],
          [:label,          "Label"                                           , false,  :none, :label,    nil    ],
          [:file,           "File Upload"                                     , true,   :none, :file,     nil    ],
          [:grid_one,       "Grid (pick one)"                                 , true,   :one,  nil,       :grid  ],
          [:grid_any,       "Grid (pick any)"                                 , true,   :any,  nil,       :grid  ],
          [:grid_dropdown,  "Group of Dropdowns"                              , true,   :one,  :dropdown, :grid  ],
          [:group_inline,   "Inline Question Group"                           , true,   :any,  :any,     :inline]
       ]      

            
        def categorize_question(question)
          all.each do |question_type|
            return question_type.id if _match_found(question, question_type)
          end
          raise "No question_type matches question #{question.id}"
#          if question.part_of_group?
#            _categorize_groups(question)
#          else
#            _categorize_picks(question)
#          end
        end
        
        def _match_found(question, question_type)
           question.part_of_group?  == question_type.part_of_group                    &&  
          (question.pick            == question_type.pick.to_s) || (question_type.pick == :any) &&
         ((question.display_type.to_s    == question_type.display_type.to_s) || 
                                       (question_type.display_type == :any))          && 
         (!question.part_of_group?  ||                                                                    
          (question.question_group.display_type == question_type.group_display_type.to_s))           
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
      
        def _categorize_groups(question)
          if question.question_group.display_type == "grid"
            case question.pick
            when 'one'
              _set_question_type(:grid_one)
            when 'any'
              _set_question_type(:grid_any)
            end
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
        
#        def _categorize_pick_one(question)
#          case question.display_type 
#          when 'slider'
#            _set_question_type(:slider)
#          when 'stars'
#            _set_question_type(:stars)
#          when 'dropdown'
#            _set_question_type(:dropdown)
#          else
#            _set_question_type(:pick_one)
#          end  
#        end
#        
#        def _categorize_no_pick(question)      
#          if question.display_type == 'label'  || !question.answers.first
#            _set_question_type(:label)
#          else
#            case question.answers.first.response_class
#            when 'text'
#              _set_question_type(:box)
#            when 'float', 'integer'
#              _set_question_type(:number)
#            when 'date'
#              _set_question_type(:date)
#            when 'blob'
#              _set_question_type(:file)
#            else
#              _set_question_type(:string)
#            end
#          end
#        end  
#        
#        def _set_question_type(id)
#          id
#        end
      end
    end
      
  end
end
