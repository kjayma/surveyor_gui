require 'rails/generators'

module SurveyorGui
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path("../templates", __FILE__)
    desc "Generate surveyor README, migrations, assets and sample survey"
    class_option :skip_migrations, :type => :boolean, :desc => "skip migrations, but generate everything else"

    MIGRATION_ORDER = %w(
      20140307204049_add_template_to_surveys
      20140307235607_add_test_data_to_response_sets
      20140308171947_add_original_choice_to_answers
      20140308172118_add_blob_to_responses
      20140308172224_add_unique_index_to_responses
      20140308172417_add_modifiable_to_survey_section
      20140308174532_add_modifiable_to_question
      20140308175305_add_dynamically_generate_to_questions
      20140311032923_add_dummy_blob_to_questions
      20140311160609_add_dynamic_source_to_questions
      20140311161714_add_report_code_to_questions
    )

    def migrations
      unless options[:skip_migrations]
        migration_files = Dir[File.join(self.class.source_root, 'db/migrate/*.rb')]
        migrations_not_in_order =
          migration_files.collect { |f| File.basename(f).sub(/\.rb$/, '') } - MIGRATION_ORDER
        unless migrations_not_in_order.empty?
          fail "%s migration%s not added to MIGRATION_ORDER: %s" % [
            migrations_not_in_order.size,
            migrations_not_in_order.size == 1 ? '' : 's',
            migrations_not_in_order.join(', ')
          ]
        end

        # because all migration timestamps end up the same, causing a collision when running rake db:migrate
        # copied functionality from RAILS_GEM_PATH/lib/rails_generator/commands.rb
        MIGRATION_ORDER.each_with_index do |model, i|
          unless (prev_migrations = Dir.glob("db/migrate/[0-9]*_*.rb").grep(/[0-9]+_#{model}.rb$/)).empty?
            prev_migration_timestamp = prev_migrations[0].match(/([0-9]+)_#{model}.rb$/)[1]
          end
          copy_file("db/migrate/#{model}.rb", "db/migrate/#{(prev_migration_timestamp || Time.now.utc.strftime("%Y%m%d%H%M%S").to_i + i).to_s}_#{model}.rb")
        end
      end
    end

    def routes
      route('mount SurveyorGui::Engine => "/surveyforms", :as => "surveyor_gui"')
    end

    def assets
      directory "app/assets"
      #copy_file "vendor/assets/stylesheets/custom.sass"
    end

  end
end
