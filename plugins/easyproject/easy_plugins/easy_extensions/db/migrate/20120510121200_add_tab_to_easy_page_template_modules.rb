class AddTabToEasyPageTemplateModules < ActiveRecord::Migration
  def self.up
    add_column :easy_page_template_modules, :tab, :integer, {:null => false, :default => 1}
  end

  def self.down
    remove_column :easy_page_template_modules, :tab
  end
end
