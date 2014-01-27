module EasyExtensions
  class DataMigrator < ActiveRecord::Migrator
    # We need to be able to set the 'current' plugin being migrated.
    cattr_accessor :current_plugin

    class << self
      def schema_migrations_table_name
        SchemaEasyDataMigration.table_name
      end

      # Runs the migrations from a plugin, up (or down) to the version given
      def migrate_plugin(plugin, version)
        self.current_plugin = plugin
        migrate(plugin.migration_easy_data_directory, version)
      end

      def current_version(plugin=current_plugin)
        # Delete migrations that don't match .. to_i will work because the number comes first
        SchemaEasyDataMigration.connection.select_values(
          "SELECT version FROM #{schema_migrations_table_name} WHERE plugin = \"#{current_plugin.id}\""
        ).map(&:to_i).max || 0
      end
    end

    def initialize(direction, migrations_paths, target_version = nil)
      raise StandardError.new("This database does not yet support migrations") unless ::ActiveRecord::Base.connection.supports_migrations?
      SchemaEasyDataMigration.create_table
      @direction, @migrations_paths, @target_version = direction, migrations_paths, target_version
    end

    def migrated
      sm_table = self.class.schema_migrations_table_name
      SchemaEasyDataMigration.connection.select_values(
        "SELECT version FROM #{sm_table} WHERE plugin = \"#{current_plugin.id}\""
      ).map(&:to_i).sort
    end

    def record_version_state_after_migrating(version)
      if down?
        migrated.delete(version)
        SchemaEasyDataMigration.where(:plugin => current_plugin.id, :version => version.to_s).delete_all
      else
        migrated << version
        SchemaEasyDataMigration.create!(:plugin => current_plugin.id, :version => version.to_s)
      end
    end
  end

  class EasyDataMigration < ActiveRecord::Migration

  end

  class SchemaEasyDataMigration < ActiveRecord::Base
    def self.table_name
      "#{SchemaEasyDataMigration.table_name_prefix}schema_easy_data_migrations#{SchemaEasyDataMigration.table_name_suffix}"
    end

    def self.index_name
      "#{SchemaEasyDataMigration.table_name_prefix}unique_schema_easy_data_migrations#{SchemaEasyDataMigration.table_name_suffix}"
    end

    def self.create_table(limit=nil)
      unless connection.table_exists?(table_name)
        version_options = {null: false}

        connection.create_table(table_name, id: false) do |t|
          t.column :plugin, :string
          t.column :version, :string, version_options
          t.column :options, :text
        end
        connection.add_index table_name, [:plugin, :version], unique: true, name: index_name
      end
    end

    def self.drop_table
      if connection.table_exists?(table_name)
        connection.remove_index table_name, name: index_name
        connection.drop_table(table_name)
      end
    end
  end
end