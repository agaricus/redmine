class TabIdentificationByIdNotPosition < ActiveRecord::Migration
  def up
    add_column :easy_page_zone_modules, :tab_id, :integer unless column_exists?(:easy_page_zone_modules, :tab_id)
    EasyPageZoneModule.all.each do |mod|
      tab = EasyPageUserTab.where(:page_id => mod.easy_pages_id, :user_id => mod.user_id, :entity_id => mod.entity_id, :position => mod.tab).first
      mod.tab_id = tab && tab.id
      mod.save
    end
    add_column :easy_page_template_modules, :tab_id, :integer unless column_exists?(:easy_page_template_modules, :tab_id)
    EasyPageTemplateModule.all.each do |mod|
      tab = EasyPageTemplateTab.where(:page_template_id => mod.easy_page_templates_id, :entity_id => mod.entity_id, :position => mod.tab).first
      mod.tab_id = tab && tab.id
      mod.save
    end
  end

  def down
    # remove_column :easy_page_zone_modules, :tab_id
    # remove_column :easy_page_template_modules, :tab_id
  end
end
