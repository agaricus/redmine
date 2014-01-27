class AddTimestampsToModules < ActiveRecord::Migration
  def self.up
    add_column :easy_page_zone_modules, :created_at, :datetime, {:null => true}
    add_column :easy_page_zone_modules, :updated_at, :datetime, {:null => true}
    add_column :easy_page_template_modules, :created_at, :datetime, {:null => true}
    add_column :easy_page_template_modules, :updated_at, :datetime, {:null => true}

    EasyPageZoneModule.reset_column_information
    EasyPageTemplateModule.reset_column_information

    EasyPageZoneModule.update_all(:created_at => Time.now)
    EasyPageZoneModule.update_all(:updated_at => Time.now)
    EasyPageTemplateModule.update_all(:created_at => Time.now)
    EasyPageTemplateModule.update_all(:updated_at => Time.now)

    change_column :easy_page_zone_modules, :created_at, :datetime, {:null => false}
    change_column :easy_page_zone_modules, :updated_at, :datetime, {:null => false}
    change_column :easy_page_template_modules, :created_at, :datetime, {:null => false}
    change_column :easy_page_template_modules, :updated_at, :datetime, {:null => false}
  end

  def self.down
    remove_column :easy_page_zone_modules, :created_at
    remove_column :easy_page_zone_modules, :updated_at
    remove_column :easy_page_template_modules, :created_at
    remove_column :easy_page_template_modules, :updated_at
  end

end