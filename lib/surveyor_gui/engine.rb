require 'rails'
require 'surveyor_gui'
require 'haml' # required for view resolution

module SurveyorGui
  class Engine < Rails::Engine
    root = File.expand_path('../../', __FILE__)
    config.autoload_paths << root

    config.to_prepare do
      require_dependency('/home/kevin/surveyor_gui/lib/surveyor_gui/models/survey_methods.rb')
#      Dir.glob(root + "/surveyor_gui/models/*.rb").each do |c|
#        require_dependency(c)
#      end
    end
  end
end
