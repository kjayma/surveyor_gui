require 'rails/generators'

module SurveyorGui
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path("../templates", __FILE__)
    desc "Generate surveyor README, migrations, assets and sample survey"
    class_option :skip_migrations, :type => :boolean, :desc => "skip migrations, but generate everything else"

    MIGRATION_ORDER = %w(
      add_template_to_surveys
      add_test_data_to_response_sets
      add_original_choice_to_answers
      add_blob_to_responses
      add_unique_index_to_responses
      add_modifiable_to_survey_section
      add_modifiable_to_question
      add_dynamically_generate_to_questions
      add_dummy_blob_to_questions
      add_dynamic_source_to_questions
      add_report_code_to_questions
    )

    def migrations
      unless options[:skip_migrations]
        migration_files = Dir[File.join(self.class.source_root, 'db/migrate/*.rb')]
        migrations_not_in_order =
          migration_files.collect { |f| File.basename(f).sub(/\d*_/,'').sub(/\.rb$/, '') } - MIGRATION_ORDER
        unless migrations_not_in_order.empty?
          fail "%s migration%s not added to MIGRATION_ORDER: %s" % [
            migrations_not_in_order.size,
            migrations_not_in_order.size == 1 ? '' : 's',
            self.class.source_root
          ]
        end

        # because all migration timestamps end up the same, causing a collision when running rake db:migrate
        # modified functionality from RAILS_GEM_PATH/lib/rails_generator/commands.rb
        last_timestamp = Dir.glob("db/migrate/[0-9]*_*.rb").sort.last.match(/(?<=\d{12})\d{2}/)[0].to_i
        MIGRATION_ORDER.each_with_index do |model, i|
          unless (prev_migrations = Dir.glob("db/migrate/[0-9]*_*.rb").grep(/[0-9]+_#{model}.rb$/)).empty?
            prev_migration_timestamp = prev_migrations[0].match(/([0-9]+)_#{model}.rb$/)[1]
          end
          cpfile = Dir[File.join(self.class.source_root,"db/migrate/*#{model}.rb")][0]
          if cpfile.empty?
            fail " failed on model %s and directory %s" % [model, Dir.glob("db/migrate/*.rb")]
          end
          modified_time = (Time.now.utc+ i + last_timestamp).strftime("%Y%m%d%H%M%S").to_i
          copy_file("#{cpfile}", "db/migrate/#{(prev_migration_timestamp || modified_time).to_s}_#{model}.rb")
        end
      end
    end

    def routes
      route('mount SurveyorGui::Engine => "/", :as => "surveyor_gui"')
    end

    def assets
      directory "app/assets"
      #copy_file "vendor/assets/stylesheets/custom.sass"
    end

  end
end
