require 'rails/generators'

module SurveyorGui
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path("../templates", __FILE__)
    desc "Generate surveyor README, migrations, assets and sample survey"
    class_option :skip_migrations, :type => :boolean, :desc => "skip migrations, but generate everything else"

    def dependencies
      generate "simple_form:install"
      generate "surveyor:install"
      rake "db:migrate db:test:prepare"

      unless options[:skip_migration]
        rake 'railties:install:migrations'
      end
      rake "db:migrate db:test:prepare"
    end

    def configurations
      replace_simple_forms_configuration_rb
      add_i18n_enforce_locales
      template 'config/initializers/chartkick.rb'
    end

    def routes
      route('mount SurveyorGui::Engine => "/surveyor_gui", :as => "surveyor_gui"')
    end

    def assets
      directory "app/assets"
      directory "app/models"
      directory "app/views"
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
