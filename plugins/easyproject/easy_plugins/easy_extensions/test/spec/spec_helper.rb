# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../../../../../../config/environment", __FILE__)

require 'factory_girl'
# Dir.glob(File.expand_path("../../factories/*", __FILE__)).each do |factory|
  # require factory
# end
Dir.glob(File.expand_path("../../../../*/test/factories/*", __FILE__)).each do |factory|
  require factory
end

require File.join(File.dirname(__FILE__), 'helper_methods')

require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'

# use phantom.js as js driver
require 'capybara/poltergeist'

easy_test_conf_file = "#{Rails.root}/plugins/easyproject/easy_plugins/easy_extensions/config/test_conf.yml"
if File.exists? (easy_test_conf_file)
  EASY_TEST_CONFIG = YAML.load_file(easy_test_conf_file)
else
  EASY_TEST_CONFIG = {}
end

def get_easy_test_conf(location, options={})
  value = EASY_TEST_CONFIG
  location.each do |locator|
    if value.is_a?(Hash)
      value = value[locator]
    else
      value = nil
    end
  end
  if value.nil?
    value ||= options[:default]
  end
  if value.nil?
    $stderr.puts "WARNING!!!! return a nil as a easy_test_conf value! Probably you forgot to set the #{location} option!"
  end
  value
end

module Capybara::Poltergeist
  class Client
    private
    def redirect_stdout
      prev = STDOUT.dup
      prev.autoclose = false
      $stdout = @write_io
      STDOUT.reopen(@write_io)

      prev = STDERR.dup
      prev.autoclose = false
      $stderr = @write_io
      STDERR.reopen(@write_io)
      yield
    ensure
      STDOUT.reopen(prev)
      $stdout = STDOUT
      STDERR.reopen(prev)
      $stderr = STDERR
    end
  end
end
class WarningSuppressor
  class << self
    def write(message)
      if message =~ /QFont::setPixelSize: Pixel size <= 0/ || message =~/CoreText performance note:/ then 0 else puts(message);1;end
    end
  end
end
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    :inspector => get_easy_test_conf(['poltergeist','inspector'], :default => true),
    :phantomjs_options => ['--ignore-ssl-errors=yes'],
    phantomjs_logger: WarningSuppressor
  })
end
Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

def persistant_tables
  EasyExtensions::Tests::EasyTestPrepare.persist_tables
end

RSpec.configure do |config|

  config.include HelperMethods

  config.default_path = 'plugins/easyproject/easy_plugins/easy_extensions/spec'
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :mocha

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/plugins/easyproject/easy_plugins/easy_extensions/test/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, :except => persistant_tables)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    setup_easyproject_app
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :deletion, {:except => persistant_tables}
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
