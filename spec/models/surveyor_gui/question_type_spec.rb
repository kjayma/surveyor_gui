# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe QuestionType do
  let(:grid)    { FactoryBot.create(:question_group, display_type: "grid") }
  let(:inline)  { FactoryBot.create(:question_group, display_type: "inline") }
  let(:repeater){ FactoryBot.create(:question_group, display_type: "inline") }

  let(:textbox)         { FactoryBot.create(
                            :question,
                            pick:             "none",
                            display_type:     "default",
                            question_group_id: nil
                          )
                        }
  let(:textbox_a)       { FactoryBot.create(
                            :answer,
                            question_id:    textbox.id,
                            response_class: :text
                          )
                        }
  let(:text)            { FactoryBot.create(
                           :question,
                           pick:             "none",
                           display_type:     "default",
                           question_group_id: nil
                          )
                        }
  let(:text_a)          { FactoryBot.create(
                            :answer,
                            question_id:    text.id,
                            response_class: :string
                          )
                        }
  let(:float)           { FactoryBot.create(
                           :question,
                           pick:             "none",
                           display_type:     "default",
                           question_group_id: nil
                         )
                        }
  let(:float_a)         { FactoryBot.create(
                            :answer,
                            question_id:    float.id,
                            response_class: :float
                          )
                        }
  let(:integer)         { FactoryBot.create(
                           :question,
                           pick:             "none",
                           display_type:     "default",
                           question_group_id: nil
                         )
                        }
  let(:integer_a)       { FactoryBot.create(
                            :answer,
                            question_id:    integer.id,
                            response_class: :integer
                          )
                        }
  let(:date)            { FactoryBot.create(
                           :question,
                           pick:             "none",
                           display_type:     "default",
                           question_group_id: nil
                         )
                        }
  let(:date_a)          { FactoryBot.create(
                            :answer,
                            question_id:    date.id,
                            response_class: :date
                          )
                        }
  let(:file)            { FactoryBot.create(
                           :question,
                           pick:             "none",
                           display_type:     "default",
                           question_group_id: nil
                         )
                        }
  let(:file_a)          { FactoryBot.create(
                            :answer,
                            question_id:    file.id,
                            response_class: :blob
                          )
                        }
  let(:label)           { FactoryBot.create(
                           :question,
                           pick:             "none",
                           display_type:     "label",
                           question_group_id: nil
                         )
                        }
  let(:pick_one)        { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "default",
                           question_group_id: nil
                         )
                        }
  let(:pick_any)        { FactoryBot.create(
                           :question,
                           pick:             "any",
                           display_type:      "default",
                           question_group_id: nil
                         )
                        }
  let(:pick_one_inline) { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "default",
                           question_group_id: inline.id
                         )
                        }
  let(:pick_any_inline) { FactoryBot.create(
                           :question,
                           pick:             "any",
                           display_type:      "default",
                           question_group_id: inline.id
                         )
                        }
  let(:dropdown)        { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "dropdown",
                           question_group_id: nil
                         )
                        }
  let(:slider)          { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "slider",
                           question_group_id: nil
                         )
                        }
  let(:stars)           { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "stars",
                           question_group_id: nil
                         )
                        }
  let(:grid_one)        { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "default",
                           question_group_id: grid.id
                         )
                        }
  let(:grid_any)        { FactoryBot.create(
                           :question,
                           pick:             "any",
                           display_type:      "default",
                           question_group_id: grid.id
                         )
                        }
  let(:grid_dropdown)   { FactoryBot.create(
                           :question,
                           pick:             "one",
                           display_type:      "dropdown",
                           question_group_id: grid.id
                         )
                        }
  let(:group_inline)   { FactoryBot.create(
                           :question,
                           pick:             "",
                           display_type:      "",
                           question_group_id: inline.id
                         )
                        }
  let(:repeater)   { FactoryBot.create(
                           :question,
                           pick:             "",
                           display_type:      "",
                           question_group_id: repeater.id
                         )
                        }


  context "when categorizing question" do
    before do
      text.reload
      text_a.reload
      textbox.reload
      textbox_a.reload
      float.reload
      float_a.reload
      integer.reload
      integer_a.reload
      date.reload
      date_a.reload
      file.reload
      file_a.reload
    end

    it "recognizes a textbox question" do
      textbox.reload
      textbox_a.reload
      expect(textbox.question_type.id).to eql :box
    end

    it "recognizes a text question" do
      expect(text.question_type.id).to eql :string
    end

    it "recognizes a float question" do
      expect(float.question_type.id).to eql :number
    end

    it "recognizes an date question" do
      expect(date.question_type.id).to eql :date
    end

    it "recognizes a file question" do
      expect(file.question_type.id).to eql :file
    end

    it "recognizes a label" do
      expect(label.question_type.id).to eql :label
    end

    it "recognizes a pick one question" do
      expect(pick_one.question_type.id).to eql :pick_one
    end

    it "recognizes a pick any question" do
      expect(pick_any.question_type.id).to eql :pick_any
    end

    it "recognizes an inline pick one question" do
      expect(pick_one_inline.question_type.id).to eql :pick_one
    end

    it "recognizes an inline pick any question" do
      expect(pick_any_inline.question_type.id).to eql :pick_any
    end

    it "recognizes a dropdown question" do
      expect(dropdown.question_type.id).to eql :dropdown
    end

    it "recognizes a slider question" do
      expect(slider.question_type.id).to eql :slider
    end

    it "recognizes a stars question" do
      expect(stars.question_type.id).to eql :stars
    end

    it "recognizes a grid one question" do
      expect(grid_one.question_type.id).to eql :grid_one
    end

    it "recognizes a grid any question" do
      expect(grid_any.question_type.id).to eql :grid_any
    end

    it "recognizes a grid dropdown question" do
      expect(grid_dropdown.question_type.id).to eql :grid_dropdown
    end

    it "recognizes a group inline question" do
      expect(group_inline.question_type.id).to eql :group_inline
    end

  end

end
