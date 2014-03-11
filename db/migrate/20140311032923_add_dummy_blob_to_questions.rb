class AddDummyBlobToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :dummy_blob, :string
  end
end
