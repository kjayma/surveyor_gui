require 'rails'
require 'surveyor-gui'
require 'haml' # required for view resolution

module SurveyorGui
  class Engine < Rails::Engine
    root = File.expand_path('../../', __FILE__)
    config.autoload_paths << root
  end
end
