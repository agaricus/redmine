class ExtendSomeTextColumns1 < ActiveRecord::Migration
  def up
    adapter_name = User.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :easy_page_zone_modules, :settings, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_page_template_modules, :settings, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :column_names, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :sort_criteria, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :settings, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
  end
end
