require 'active_record/fixtures'

module EasyExtensions
  module Tests

    class FixturesSet
      attr_accessor :path, :fixtures
      def initialize(path, fixtures)
        self.path, self.fixtures = path, fixtures
      end

      def create
        ActiveRecord::Fixtures.create_fixtures(path, fixtures)
      end
    end

    class EasyTestPrepare

      @prepares = []

      class << self
        attr_reader :prepares
        private :new

        def def_field(*names)
          class_eval do
            names.each do |name|
              define_method(name) do |*args|
                args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
              end
            end
          end
        end
      end

      def_field :directory

      def self.persist_tables=(tables)
        raise ArgumentError, 'Tables has to be array of tables' unless tables.is_a?(Array)
        @persist_tables = tables
      end
      def self.persist_tables
        @persist_tables ||= ['settings', 'easy_settings']
      end

      def self.to_prepare(&block)
        p = new
        p.instance_eval(&block)
        @prepares << p
      end

      def self.prepare!
        DatabaseCleaner.clean_with(:truncation)
        @prepares.each{|prep| prep.prepare! }
      end

      def prepare!
        @persist_table_fixtures.each do |fix_set|
          fix_set.create
          self.class.persist_tables |= fix_set.fixtures.map{|table| table.to_s}
        end
        redmine_settings.each do |name, value|
          Setting.create(:name => name, :value => value)
        end
        easy_settings.each do |name, value|
          EasySetting.create(:name => name, :value => value)
        end
      end

      def default_fixture_path
        raise 'Please set the directory variable if you want to use default paths' unless self.directory
        File.join(self.directory, 'test', 'fixtures')
      end

      def persist_table_fixtures(tables, path=nil)
        path ||= self.default_fixture_path

        @persist_table_fixtures ||= []
        @persist_table_fixtures << FixturesSet.new(path, tables)
      end

      def redmine_settings
        @redmine_settings ||= {}
      end

      def easy_settings
        @easy_settings ||= {}
      end

      def easy_settings_from_yml(yaml)
        yaml.each do |name, setting|
          easy_settings[name] = setting['default']
        end
      end

    end

  end
end