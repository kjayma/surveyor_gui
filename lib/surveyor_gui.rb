module SurveyorGui
  require 'surveyor_gui/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  autoload :VERSION, 'surveyor_gui/version'
end
require 'will_paginate'
require 'simple_form'
require 'colorbox-rails'
require 'jquery-form-rails'
require 'carrierwave'
require 'surveyor'
require 'dynamic_form'
