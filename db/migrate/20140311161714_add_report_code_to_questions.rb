class AddReportCodeToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :report_code, :string
  end
end
