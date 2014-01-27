class ChangeEasyRakeTasksBuiltin < ActiveRecord::Migration
  def self.up
    EasyRakeTask.reset_column_information

    EasyRakeTask.where(["#{EasyRakeTask.table_name}.builtin > 0"]).update_all(:builtin => -1)
    EasyRakeTask.where(["#{EasyRakeTask.table_name}.builtin = 0"]).update_all(:builtin => 1)
    EasyRakeTask.where(["#{EasyRakeTask.table_name}.builtin = -1"]).update_all(:builtin => 0)
  end

  def self.down
  end
end