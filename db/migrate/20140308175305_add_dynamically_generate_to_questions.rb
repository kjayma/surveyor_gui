class AddDynamicallyGenerateToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :dynamically_generate, :boolean, :default=>false
  end
end
