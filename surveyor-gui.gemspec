$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "surveyor-gui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "surveyor-gui"
  s.version     = SurveyorGui::VERSION
  s.authors     = ["Kevin Jay"]
  s.email       = ["kjayma@gmail.com"]
  s.homepage    =  %q{http://github.com/kjayma/surveyor-gui}
  s.post_install_message = %q{Thanks for installing surveyor-gui! The time has come to run the surveyor-gui generator and migrate your database, even if you are upgrading.}
  s.summary     = "A Rails gem to supply a front-end and reporting capability to the Surveyor gem."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.17"

  s.add_development_dependency "sqlite3"

  s.add_development_dependency 'sass-rails', '~> 3.2.3'
  s.add_development_dependency 'coffee-rails', '~> 3.2.1'
  s.add_development_dependency 'uglifier', '>= 1.0.3'

  s.add_development_dependency 'debugger'

  s.add_dependency 'surveyor', '~> 1.4.0'
  s.add_dependency 'will_paginate', '~> 3.0.5'

  s.add_dependency 'simple_form', '~> 2.1.1'
  s.add_dependency 'carrierwave'
  s.add_dependency 'colorbox-rails'
  s.add_dependency 'jquery-form-rails'
end
