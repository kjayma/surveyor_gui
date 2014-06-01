class CreateRows < ActiveRecord::Migration
  def change
    create_table :rows do |t|
      t.integer :question_group_id
      t.string :text
      t.timestamps
    end
  end
end
