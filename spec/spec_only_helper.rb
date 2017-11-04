ENV["RAILS_ENV"] ||= 'test'

require 'rspec'

require 'rspec/mocks'
require 'rspec/collection_matchers'

require 'factories'
require 'json_spec'
require 'database_cleaner'
require 'rspec/retry'

require 'factory_girl'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

Dir["./spec/factories/**/*.rb"].sort.each {|f| require f}

RSpec.configure do |config|
  config.include JsonSpec::Helpers

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # use both old 'should' syntax and the newer 'expect' syntax:
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end


  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #config.use_transactional_fixtures = true


  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"


  config.include FactoryGirl::Syntax::Methods




end


JsonSpec.configure do
  exclude_keys "id", "created_at", "updated_at", "uuid", "modified_at", "completed_at"
end
