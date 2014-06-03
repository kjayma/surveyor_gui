require 'rails'
require 'surveyor_gui'
require 'haml' # required for view resolution

module SurveyorGui
  class Engine < Rails::Engine
    root = File.expand_path('../../', __FILE__)
    config.autoload_paths << root

    config.to_prepare do
      Dir.glob(root + "/surveyor_gui/models/*.rb").each do |c|
        require_dependency(c)
      end
      Dir.glob(root + "/surveyor_gui/helpers/*.rb").each do |c|
        require_dependency(c)
      end
      c = Dir.glob(File.expand_path('../',root)+'/app/controllers/surveyor_controller.rb').first
      require_dependency(c)
      Dir.glob(File.expand_path('../',root)+'/app/models/*.rb').each do |c|
        require_dependency(c)
      end
    end
  end
end
