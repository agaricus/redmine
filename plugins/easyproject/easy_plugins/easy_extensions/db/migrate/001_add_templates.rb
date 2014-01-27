class AddTemplates < ActiveRecord::Migration
  def self.up
    add_column :projects, :easy_is_easy_template, :boolean, {:null => true, :default => false}
    add_column :issues, :easy_is_easy_template, :boolean, {:null => true, :default => false}
  end

  def self.down
    remove_column :projects, :easy_is_easy_template
    remove_column :issues, :easy_is_easy_template
  end
end
