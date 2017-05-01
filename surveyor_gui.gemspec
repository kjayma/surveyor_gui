$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "surveyor_gui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "surveyor_gui"
  s.version     = SurveyorGui::VERSION
  s.authors     = ["Kevin Jay", "Ashley Engelund"]
  s.email       = ["kjayma@gmail.com", "ashley@ashleycaroline.com"]
  s.homepage    =  %q{http://github.com/weedySeaDragon/surveyor_gui}

  s.post_install_message = %q{Thanks for installing surveyor_gui! The time has come to run the surveyor_gui generator and migrate your database, even if you are upgrading.}
  s.summary     = "Ashley Engelund's modifications to surveyor_gui: Rspec 3, jquery-ui (vs. -sass-rails). A Rails gem to supply a front-end and reporting capability to the Surveyor gem."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  #s.files = `git ls-files`.split("\n") - ['irb']

  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  # s.executables = ['surveyor_gui']


  s.require_paths = ["lib"]

  # ruby version 2.4.0 or greater
  s.required_ruby_version = '~> 2.4.0', '>= 2.4.0'
    # this version is required for capybara-webkit


  s.add_dependency 'rails', '~> 4.2.8',  '>= 4.2.0'
  s.add_dependency 'dynamic_form', '~> 1.1.4'

  s.add_dependency 'jquery-ui-rails'

  s.add_dependency 'surveyor', '~> 1.5.7', '>= 1.5.1'  # ruby 2.4.0
  s.add_dependency 'will_paginate', '~> 3.0.5'

  s.add_dependency 'simple_form', '~> 3.3.1'
  s.add_dependency 'carrierwave'
  s.add_dependency 'colorbox-rails', '~> 0.1.1'
  s.add_dependency 'jquery-form-rails', '~> 1.0.1'
  s.add_dependency 'deep_cloneable', '~> 2.0.0'
  s.add_dependency 'lazy_high_charts'

  s.add_dependency 'formtastic'


  s.add_development_dependency "sqlite3"


  s.add_development_dependency 'sass-rails','~> 4.0.2'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'uglifier', '>= 1.0.3'
  s.add_development_dependency('rspec-rails', '~> 3.5.2')
  s.add_development_dependency('web-console', '~> 2.0')
  s.add_development_dependency('byebug')

  s.add_development_dependency('rspec-collection_matchers')
  s.add_development_dependency('capybara')
  s.add_development_dependency('launchy', '~> 2.4.2')
  s.add_development_dependency('poltergeist', '~>1.9.0')
  s.add_development_dependency('capybara-webkit', '~> 1.14.0')

  s.add_development_dependency('json_spec', '~> 1.1.1')
  s.add_development_dependency('factory_girl', '~> 4.4.0')
  s.add_development_dependency('database_cleaner', '~> 1.2.0')
  s.add_development_dependency('rspec-retry')

end
