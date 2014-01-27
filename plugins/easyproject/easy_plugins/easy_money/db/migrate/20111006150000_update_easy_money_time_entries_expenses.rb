class UpdateEasyMoneyTimeEntriesExpenses < ActiveRecord::Migration
  def self.up
    EasyMoneyTimeEntryExpense.update_all_projects_time_entry_expenses(Project.non_templates.active.has_module(:easy_money).pluck(:id))
  end

  def self.down
  end
end