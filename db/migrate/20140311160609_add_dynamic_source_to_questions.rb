class AddDynamicSourceToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :dynamic_source, :string
  end
end
