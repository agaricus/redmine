class ChangeColumnsForMysqlInTextileMigrator < ActiveRecord::Migration
  def up
    adapter_name = EasyTextileMigrator.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :easy_textile_migrators, :source_text, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_textile_migrators, :target_text, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
  end

end
