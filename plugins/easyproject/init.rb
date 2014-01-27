require 'pp'

unless RUBY_VERSION > '1.9'
  $stderr.puts "Only Ruby 1.9.3 and higher is supported!"
  exit
end

module Redmine
  class Plugin

    @disabled_plugins = {}
    class << self
      attr_reader :disabled_plugins
    end

    def_field :visible, :migration_order, :version_description, :disabled, :should_be_disabled
    attr_reader :complete_directory_path

    def plugin_in_relative_subdirectory(subdir)
      @complete_directory_path = File.join(self.class.directory, subdir)
    end

    def visible?
      @visible = true if @visible.nil?
      visible == true
    end

    def disabled?
      disabled == true
    end

    def should_be_disabled?
      @should_be_disabled = true if @should_be_disabled.nil?
      should_be_disabled == true
    end

    def migration_directory
      File.join(directory, 'db', 'migrate')
    end

    def self.all(options={})
      options ||= {}
      only_visible = options.key?(:only_visible) ? options.delete(:only_visible) : false
      without_disabled = options.key?(:without_disabled) ? options.delete(:without_disabled) : false

      arr = []
      arr += registered_plugins.values
      arr += disabled_plugins.values unless without_disabled

      arr.select{|p| only_visible ? p.visible? : true}.sort do |a, b|
        comp = ((a.migration_order || 1000) <=> (b.migration_order || 1000))
        comp.zero? ? (a.id.to_s <=> b.id.to_s) : comp
      end
    end

    def self.find_or_nil(id)
      p = registered_plugins[id.to_sym]
      p ||= disabled_plugins[id.to_sym]
      p
    end

    def self.register(id, &block)
      p = new(id)
      p.instance_eval(&block)

      # Set a default name if it was not provided during registration
      p.name(id.to_s.humanize) if p.name.nil?
      # Set a default directory if it was not provided during registration
      p.directory(File.join(p.complete_directory_path || self.directory, id.to_s)) if p.directory.nil?

      if p.disabled?
        disabled_plugins[id] = p
        return
      end

      # Adds plugin locales if any
      # YAML translation files should be found under <plugin>/config/locales/
      ::I18n.load_path += Dir.glob(File.join(p.directory, 'config', 'locales', '*.yml'))

      # Prepends the app/views directory of the plugin to the view path
      view_path = File.join(p.directory, 'app', 'views')
      if File.directory?(view_path)
        ActionController::Base.prepend_view_path(view_path)
        ActionMailer::Base.prepend_view_path(view_path)
      end

      # Adds the app/{controllers,helpers,models} directories of the plugin to the autoload path
      Dir.glob File.expand_path(File.join(p.directory, 'app', '{controllers,helpers,models}')) do |dir|
        ActiveSupport::Dependencies.autoload_paths += [dir]
      end

      registered_plugins[id] = p
    end

    def self.migrate(name=nil, version=nil)
      if name.present?
        p = find_or_nil(name)
        p.migrate(version) if p
      else
        all.each do |plugin|
          plugin.migrate
        end
      end
    end

    def self.migrate_easy_data(name=nil, version=nil)
      if name.present?
        p = find_or_nil(name)
        p.migrate_easy_data(version) if p
      else
        all.each do |plugin|
          plugin.migrate_easy_data
        end
      end
    end

    def migrate_easy_data(version = nil)
      puts "Migrating data for #{id} (#{name})..."
      EasyExtensions::DataMigrator.migrate_plugin(self, version)
    end

    def migration_easy_data_directory
      File.join(directory, 'db', 'data')
    end

  end
end

module EasyProjectLoader
  def self.can_start?
    Rails.env.test? || Setting.table_exists?
  end
end

if EasyProjectLoader.can_start?
  ::I18n.load_path += Dir["#{Rails.root}/config/locales/*"]
  easyproject_plugins = []
  easyproject_plugins.concat(Dir.glob(File.join(Rails.root, 'plugins', 'easyproject', 'easy_helpers', '*')).sort)
  easyproject_plugins.concat(Dir.glob(File.join(Rails.root, 'plugins', 'easyproject', 'easy_plugins', 'easy_extensions')))
  easyproject_plugins.concat(Dir.glob(File.join(Rails.root, 'plugins', 'easyproject', 'easy_plugins', '*')).select{|x| File.basename(x) != 'easy_extensions'}.sort)

  # Do not include modifications and google translator in test environment
  if Rails.env.test?
    easyproject_plugins.delete_if { |p| p =~ /easy_google_translator$/ || p =~ /modification_easysoftware$/ }
  end

  easyproject_plugins.each do |easyproject_plugin|

    Dir.glob(File.expand_path(File.join(easyproject_plugin, 'app', '{sweepers,models/easy_page_modules,models/easy_queries,models/easy_rakes}'))) do |dir|
      ActiveSupport::Dependencies.autoload_paths += [dir]
    end

    lib = File.join(easyproject_plugin, 'lib')
    if File.directory?(lib)
      $:.unshift lib
      ActiveSupport::Dependencies.autoload_paths += [lib]
    end

    initializer = File.join(easyproject_plugin, 'init.rb')
    if File.file?(initializer)
      #config = config = RedmineApp::Application.config
      #eval(File.read(initializer), binding, initializer)
      require initializer
    end

    if easyproject_plugin =~ /\/easyproject\/easy_plugins\//
      plugin = Redmine::Plugin.find_or_nil(File.basename(easyproject_plugin))
      if plugin && plugin.disabled?
        next
      end
    end

    initializer = File.join(easyproject_plugin, 'after_init.rb')
    if File.file?(initializer)
      require initializer
    end

    file = File.join(easyproject_plugin, 'config/routes.rb')
    if File.exists?(file)
      begin
        RedmineApp::Application.routes.prepend do
          instance_eval File.read(file)
        end
      rescue Exception => e
        puts "An error occurred while loading the routes definition of #{File.basename(easyproject_plugin)} plugin (#{file}): #{e.message}."
        exit 1
      end
    end

    # loads an test data or environment variables
    if Rails.env.test?
      test_initializer = File.join(easyproject_plugin, 'test_init.rb')
      if File.file?(test_initializer)
        require test_initializer
      end
    end
  end
  if Rails.env.test?
    require File.join(Rails.root, 'plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'lib', 'easy_extensions', 'tests', 'easy_test_prepare')
    EasyExtensions::Tests::EasyTestPrepare.prepare!
  end
else
  $stderr.puts "The Easy Project cannot start because the Redmine is not migrated!\n" +
    "Please run `bundle exec rake db:migrate RAILS_ENV=production`\n" +
    "and than `bundle exec rake easyproject:install RAILS_ENV=production`"
end


class EasyLoadPath < Array
  def +(arr)
    EasyLoadPath.new(super.uniq)
  end
end
I18n.load_path = EasyLoadPath.new(I18n.load_path)
