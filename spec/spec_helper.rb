# Rails and Capybara related requirements and configuration

# This file is customized to run specs withing the testbed environemnt

# TODO complete the refactoring of tests so this file can be renamed to 'rails_helper'

require 'spec_only_helper'


ENV["RAILS_ENV"] ||= 'test'
begin
  require File.expand_path("../../test/dummy/config/environment", __FILE__)
rescue LoadError => e
  fail "Could not load the testbed app. Have you generated it?\n#{e.class}: #{e}"
end

require 'rspec/rails'

require 'rspec/rails/matchers'

require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
# require 'capybara/webkit'

require 'rack/utils'


Capybara.app = Rack::ShowExceptions.new(Dummy::Application)
# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
#ActiveRecord::Migration.maintain_test_schema! if ::Rails.version >= "4.0" && defined?(ActiveRecord::Migration)


Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, debug: false)
end

Capybara.server_port = 3001
Capybara.asset_host = "http://lvh.me:3001"

#Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|

  config.include SurveyorAPIHelpers
  config.include SurveyorUIHelpers
  config.include WaitForAjax

  config.include Capybara::DSL


  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"


  # host
  config.before :each do
  #  host = "lvh.me:"+Capybara.current_session.driver.server.port.to_s
  ##  puts host
  #  Capybara.asset_host = "http://#{host}"
  #  Rails.application.routes.default_url_options[:host] = host
  ##    #"lvh.me:"+Capybara.current_session.driver.server.port.to_s
  end


  # Database Cleaner
  config.before :suite do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end


  config.before :each do |example|

    if example.metadata[:clean_with_truncation] || example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start

  end

  config.after :each do
    Capybara.reset_sessions!
  end


  config.after :each do
    Capybara.reset_sessions!
    DatabaseCleaner.clean
  end


end
