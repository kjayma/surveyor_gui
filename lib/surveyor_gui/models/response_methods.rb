module SurveyorGui
  module Models
    module ResponseMethods

      def self.included(base)
        base.send :has_many, :answers, :primary_key => :answer_id, :foreign_key => :id
        base.send :has_many, :questions
        base.send :attr_accessible, :response_set, :question, :answer, :date_value, :time_value,
            :response_set_id, :question_id, :answer_id, :datetime_value, :integer_value, :float_value,
            :unit, :text_value, :string_value, :response_other, :response_group, :survey_section_id, :blob if defined? ActiveModel::MassAssignmentSecurity
        #belongs_to :user

        # after_destroy :delete_blobs!
        # after_destroy :delete_empty_dir

        #extends response to allow file uploads.
        base.send :mount_uploader, :blob, BlobUploader
      end

      def response_value
        if float_value
          float_value
        elsif integer_value
          integer_value
        elsif string_value
          string_value
        elsif datetime_value
          datetime_value
        elsif text_value
          text_value
        elsif string_value
          string_value
        end
      end

    private

      def delete_blobs!
          self.remove_blob!
      end


      def delete_empty_dir
        FileUtils.rm_rf(File.join(Rails.root.to_s,'public',BlobUploader.store_dir))
      end
    end
  end
end
