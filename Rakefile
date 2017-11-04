$LOAD_PATH << File.expand_path('../lib', __FILE__)


require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

###### RSPEC

#RSpec::Core::RakeTask.new(:spec)

#RSpec::Core::RakeTask.new(:rcov) do |spec|
#  spec.rcov = true
#end

task :default => :spec


###### TESTBED

desc 'Set up the rails app that the specs and features use'
task :gui_testbed => 'gui_testbed:rebuild'

namespace :gui_testbed do
  desc 'Generate a minimal surveyor_gui/surveyor rails app'
  task :generate do
    sh "bundle exec rails new testbed --skip-bundle" # don't run bundle install until the Gemfile modifications

    chdir('testbed') do
      gem_file_contents = File.read('Gemfile')
      gem_file_contents.sub!(/^(gem 'rails'.*)$/, %Q{ \\1\nplugin_root = File.expand_path('../..', __FILE__)\ngem 'surveyor_gui', :path => plugin_root\ngem 'therubyracer'\ngem 'surveyor', github: 'NUBIC/surveyor'})

      File.open('Gemfile', 'w'){|f| f.write(gem_file_contents) }

      # not sure why turbolinks gives test problems, anyway better to avoid it?
      js_file_contents = File.read('app/assets/javascripts/application.js')
      js_file_contents.sub!('//= require turbolinks', '')
      File.open('app/assets/javascripts/application.js', 'w'){|f| f.write(js_file_contents) }

      Bundler.with_clean_env do
        sh 'bundle install' # run bundle install after Gemfile modifications
      end
    end
  end

  desc 'Remove the testbed entirely'
  task :remove do
    rm_rf 'testbed'
  end

  desc 'Prepare the databases for the testbed'
  task :migrate do
    chdir('testbed') do
      Bundler.with_clean_env do
        # AE: no need to manually install these and surveyor; they are installed when surveyor_gui is installed
          #sh 'bundle exec rails generate simple_form:install'

          #sh 'bundle exec rails generate surveyor:install'
          #sh 'bundle exec rake db:migrate db:test:prepare'

        sh 'bundle exec rails generate surveyor_gui:install'
        sh 'bundle exec rake db:migrate db:test:prepare'

        sh 'bundle exec rake surveyor FILE=surveys/kitchen_sink_survey.rb'
      end
    end
  end

  task :rebuild => [:remove, :generate, :migrate]
end
