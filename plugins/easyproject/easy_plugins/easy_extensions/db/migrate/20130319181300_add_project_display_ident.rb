class AddProjectDisplayIdent < ActiveRecord::Migration
  def up
    return if EasySetting.where(:name => 'project_display_identifiers').exists?
    
    begin
      EasySetting.create(:name => 'project_display_identifiers', :value => Setting.sequential_project_identifiers?)
    rescue
      EasySetting.create(:name => 'project_display_identifiers', :value => false)
    end
  end

  def down
    EasySetting.where(:name => 'project_display_identifiers').destroy_all
  end

end
