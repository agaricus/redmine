class RenameEasyRepeatingRakeTask < ActiveRecord::Migration
  def up
    EasyRakeTask.where(:type => 'EasyRakeTaskRepeatingIssues').update_all(:type => 'EasyRakeTaskRepeatingEntities')
  end

  def down
  end
end
