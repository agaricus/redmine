class ChangeOrAddIndexes < ActiveRecord::Migration
  def self.up
    remove_index :easy_page_zone_modules, :name => 'idx_easy_page_zone_modules_1'
    add_index :easy_page_zone_modules, [:easy_pages_id, :easy_page_available_zones_id, :user_id, :entity_id], :name => 'idx_easy_page_zone_modules_1'

    add_index :easy_page_template_modules, [:easy_page_templates_id, :easy_page_available_zones_id, :entity_id], :name => 'idx_easy_page_template_modules_3'

    add_index :easy_queries, [:id, :type], :name => 'idx_easy_queries_1'

    add_index :projects, [:lft, :rgt], :name => 'idx_projects_1'
    add_index :projects, [:lft], :name => 'idx_projects_2'

    add_index :issues, [:lft], :name => 'idx_issues_1'

    add_index :users, [:lft], :name => 'idx_users_1'
  end

  def self.down
  end
end
