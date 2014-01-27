class EasyPageModuleNewIssueSettingsUpdate < ActiveRecord::Migration
  def up
    modules =  EasyPageZoneModule.joins(:module_definition).readonly(false).where("#{EasyPageModule.table_name}" => {:type => 'EpmIssuesCreateNew'})
    modules.each do |mod|
      next unless mod.settings['show_fields_option'] == 'only_selected'
      next unless mod.settings['selected_fields'].is_a?(Hash)
      mod.settings['selected_fields']['status_id'] = mod.settings['selected_fields'].delete('issue_status_id')
      mod.settings['selected_fields']['priority_id'] = mod.settings['selected_fields'].delete('issue_priority_id')
      mod.save
    end
  end

  def down
  end
end
