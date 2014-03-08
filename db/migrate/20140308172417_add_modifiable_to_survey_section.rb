class AddModifiableToSurveySection < ActiveRecord::Migration
  def change
    add_column :survey_sections, :modifiable, :boolean, :default=>true
  end
end
