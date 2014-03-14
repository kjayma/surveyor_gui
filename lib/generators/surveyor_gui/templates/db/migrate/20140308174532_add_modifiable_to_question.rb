class AddModifiableToQuestion < ActiveRecord::Migration
  def change
    add_column :questions, :modifiable, :boolean, :default=>true
  end
end
