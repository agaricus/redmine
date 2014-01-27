unless Rails.env.production?

require 'rspec/core'
require 'rspec/core/rake_task'
require 'rspec/core/formatters/json_formatter'

require File.expand_path('../../easy_extensions/tests/redmine_rake_task', __FILE__)

#USAGE
# -- RUNING LOCALY
# => easyproject:tests - runs all tests
# => easyproject:tests:easy - runs only easyproject tests

# -- RUNNING REMOTELY BY MACHINE AND REPORT TO ISSUE
# => easyproject:tests:all_and_report[<server>,<issue_id>,<api_key>]

# -- EASYPROJECT TESTS
# -- rspec tests
# => easyproject:tests:spec - user output
# => easyproject:tests:spec[<tag>] - defined tag inclusion/exclusion
# => easyproject:tests:spec[default,json] - computional output (json formated output)

# -- REDMINE TESTS
# => easyproject:tests:redmine - runs a working redmine tests (already patched to work)
# => easyproject:tests:redmine FN=<*file_name> TN=<test_name>  /test_name not required Where for example file_name=projects_controller and test_name=test_archive
# => easyproject:tests:all - runs all redmine tests ( with easypatches, but runs unpatched too)


namespace :easyproject do
  namespace :tests do


    def initialize_test_environment

      # test_initializer = File.join(easyproject_plugin, 'test', 'init.rb')
      # if File.file?(test_initializer)
      #   config = RedmineApp::Application.config
      #   eval(File.read(test_initializer), binding, test_initializer)
      # end

    end

    # output = :user/:machine
    # options
    # => :only_easy - true - refuses a redmine tests
    def selected_rakes(output=:user, options={})
      rakes = []
      if !options[:only_easy]
        rakes << 'easyproject:tests:redmine'
      end
      rakes << ['easyproject:tests:spec', {:parser => 'rspec_json', :machine => '[all,json]'}]

      rakes
    end

    def rakes_as_array(output=:user, options={})
      result = selected_rakes(output, options).collect do |rake|
        if rake.is_a?(Array)
          rake, rake_options = rake.first, rake.second
        else
          rake_options = {}
        end
        rake += rake_options[output] if rake_options[output]
        rake
      end
    end

    def add_rakes_to_parse(parser, options={})
      selected_rakes(:machine, options).each do |rake|
        if rake.is_a?(Array)
          rake, options = rake.first, rake.second
        else
          options = {}
        end

        rake += options[:machine] if options[:machine]
        parser.add_rake(rake, options[:parser])
      end
    end

    # can not be run as dependencies cuz if test failed, it abort rake
    def run_rakes(output=:user, options={})
      rakes_as_array(output,options).each do |rake|
        puts "running a rake #{rake}"
        begin
          Rake::Task[rake].invoke
        rescue
        end
      end
    end

    desc 'Runs selected tasks with user output'
    task :all do
      run_rakes
    end

    task :easy do
      run_rakes(:user, :only_easy => true)
    end

    task :all_and_report,[:server, :issue_id, :api_key] do |t, params|
      require File.expand_path('../../easy_extensions/tests/rake_test_parser', __FILE__)
      require File.expand_path('../../easy_extensions/tests/test_reporter', __FILE__)

      # parser = EasyExtensions::Tests::RakeTestParser.new(['easyproject:tests:units', 'easyproject:tests:functionals', 'easyproject:tests:integration', 'easyproject:tests:ui'])
      reporter = EasyExtensions::Tests::TestReporter.new(params[:server], params[:issue_id], params[:api_key])
      parser = EasyExtensions::Tests::RakeTestParser.new([])
      add_rakes_to_parse(parser)

      parser.run_all

      reporter.report(parser)
    end

    desc "write current state of development table easy_setting to yml file for test usage"
    task :write_settings => :environment do
      settings = EasySetting.all.inject({}) do |mem, set|
        mem[set.name] = { 'default' => set.value } unless [set.project_id]
        mem
      end
      file = File.expand_path('../../../config/easy_settings.yml', __FILE__)
      File.write(file, settings.to_yaml)
    end

    # just as example
    # if all our test will be in RSpec we don't need a Open3 and parse outpu
    task :spec_reported do
      config = RSpec.configuration
      config.color = true
      json_formatter = RSpec::Core::Formatters::JsonFormatter.new(config.output)

      # set up the reporter with this formatter
      reporter =  RSpec::Core::Reporter.new(json_formatter)
      config.instance_variable_set(:@reporter, reporter)

      RSpec::Core::Runner.run(['plugins/easyproject/easy_plugins/easy_extensions/test/spec/controllers/templates_controller_spec.rb'])

      pp json_formatter.output_hash
    end


    namespace :redmine do

      def working_redmine_test_files
        [
          'test/functional/admin_controller_test.rb',
          'test/functional/auth_sources_controller_test.rb',
          'test/functional/custom_fields_controller_test.rb',
          'test/functional/enumerations_controller_test.rb',
          'test/functional/groups_controller_test.rb',
          'test/functional/issue_statuses_controller_test.rb',
          'test/functional/projects_controller_test.rb',
          'test/functional/roles_controller_test.rb',
          'test/functional/settings_controller_test.rb',
          'test/functional/trackers_controller_test.rb',
          'test/functional/users_controller_test.rb',
          'test/functional/workflows_controller_test.rb'
        ]
      end

      desc 'Runs all redmine tests with patches'
      EasyExtensions::Tests::RedmineRakeTask.new :all

      desc 'Runs already working redmine tests, or selected test file'
      EasyExtensions::Tests::RedmineRakeTask.new :working do |t|
        file_name = ENV['FN']
        test_name = ENV['TN']
        if file_name
          t.pattern = "test/*/#{file_name}*_test.rb"
          t.options = "-n#{test_name}" if test_name
        else
          t.test_files = working_redmine_test_files
        end
      end

      # just an example of selecting some specific tests
      desc 'Runs selected watchers redmine tests'
      EasyExtensions::Tests::RedmineRakeTask.new :watchers_c do |t|
        t.verbose = true
        t.test_files = ['test/functional/watchers_controller_test.rb']
        t.options = '-n "/test_(un)?watch/"'
      end

    end
    task :redmine => 'redmine:working'

    desc 'Runs all Easy Project unit tests.'
    Rake::TestTask.new :units => "db:test:prepare" do |t|
      t.libs << "test"
      t.verbose = true
      t.pattern = "plugins/easyproject/easy_plugins/#{ENV['NAME'] || '*'}/test/unit/**/*_test.rb"
    end

    desc 'Runs all Easy Project functional tests.'
    # Rake::TestTask.new :functionals => "db:test:prepare" do |t|
    Rake::TestTask.new :functionals do |t|
      t.libs << "test"
      t.verbose = true
      t.pattern = "plugins/easyproject/easy_plugins/#{ENV['NAME'] || '*'}/test/functional/**/*_test.rb"
    end

    desc 'Runs all Easy Project integration tests.'
    Rake::TestTask.new :integration => "db:test:prepare" do |t|
      t.libs << "test"
      t.verbose = true
      t.pattern = "plugins/easyproject/easy_plugins/#{ENV['NAME'] || '*'}/test/integration/**/*_test.rb"
    end

    desc 'Run the UI tests with Capybara (PhantomJS listening on port 4444 is required)'
    Rake::TestTask.new :ui => "db:test:prepare" do |t|
      t.libs << "test"
      t.verbose = true
      t.pattern = "plugins/easyproject/easy_plugins/#{ENV['NAME'] || '*'}/test/ui/**/*_test.rb"
      #t.test_files = FileList["test/ui/**/*_test.rb"]
    end

    desc 'Runs rspec tests.'
    RSpec::Core::RakeTask.new(:spec, :tag, :format) do |t, task_args|
      format = task_args[:format] #|| 'documentation'
      unless task_args[:tag] == 'all'
        tag = task_args[:tag] == 'default' ? '~slow' : task_args[:tag]
        tag ||= '~slow'
      end
      spec_helper = File.expand_path('../../../test/spec/spec_helper', __FILE__)
      t.verbose = false
      t.ruby_opts = "-r \"#{spec_helper}\""
      t.pattern = "./plugins/easyproject/easy_plugins/#{ENV['NAME'] || '*'}/test/spec{,/*/**}/#{ENV['FN'] || '*'}_spec.rb"
      t.rspec_opts = ''
      t.rspec_opts << "--format #{format} " if format
      t.rspec_opts << "--tag #{tag} " if tag
    end

  end

  task :tests => 'tests:all'
end

end # pokud neni produkce
