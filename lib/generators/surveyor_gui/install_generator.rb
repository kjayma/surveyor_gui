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

    def configurations
      replace_simple_forms_configuration_rb
      remove_surveyor_require_jquery_css
      add_i18n_enforce_locales
    end

    def routes
      route('mount SurveyorGui::Engine => "/", :as => "surveyor_gui"')
    end

    def assets
      directory "app/assets"
    end

    private

    def replace_simple_forms_configuration_rb
      #formatting of radio buttons and checkboxes sensitive to the configuration.
      #The newer version of simple_forms defaults to a form_building approach
      #that changes the wrapping of input fields; it breaks selectors in jquery
      #code.  Flipping a few switches in the configuration gets the code to work.
      remove_file File.expand_path('config/initializers/simple_form.rb',Rails.root)
      template "config/initializers/simple_form.rb"
    end

    def remove_surveyor_require_jquery_css
      #comment line in surveyor_all.css manifest that steps on jquery-ui-rails.
      #this is somewhat brittle because it assumes surveyor:install generator will
      #always be run before this generator.
      gsub_file "app/assets/stylesheets/surveyor_all.css",
        /^\*=(.*jquery-ui-\d.*custom.*$)/,
        '*\1'
    end

    def add_i18n_enforce_locales
      #gets rid of 18n deprecation message:
      #"I18n.enforce_available_locales will default to true in the future. If you really
      #want to skip validation of your locale you can set I18n.enforce_available_locales
      #= false to avoid this message."
      inject_into_file "config/application.rb",
        "config.i18n.enforce_available_locales = true",
        :after => "config.encoding = \"utf-8\"\n"
    end
  end
end
