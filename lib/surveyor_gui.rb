require 'surveyor'

module SurveyorGui
  require 'surveyor_gui/engine' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
  autoload :VERSION, 'surveyor_gui/version'
end

require 'jquery-rails'
require 'sass-rails'
require 'jquery-ui-rails'

require 'will_paginate'
require 'simple_form'
require 'colorbox-rails'
require 'jquery-form-rails'
require 'carrierwave'
require 'dynamic_form'
require 'enumerable_extenders'
require 'chartkick'
