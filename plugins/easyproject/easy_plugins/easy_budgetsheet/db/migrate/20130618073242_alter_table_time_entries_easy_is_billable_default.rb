class AlterTableTimeEntriesEasyIsBillableDefault < ActiveRecord::Migration
  def up
    change_column(:time_entries, :easy_is_billable, :boolean, {:null => true, :default => nil})
    EasySetting.create(:name => 'billable_things_default_state', :value => true)
  end

  def down
    change_column(:time_entries, :easy_is_billable, :boolean, {:null => false, :default => false})
    EasySetting.where(:name => 'billable_things_default_state').delete_all
  end
end
