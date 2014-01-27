class AddDefaultColumnsToEasyTimeEntryQuerySettings < ActiveRecord::Migration
  def self.up
    budgetsheet_setting = EasySetting.find_by_name('easy_time_entry_query_list_default_columns')
    if budgetsheet_setting && !budgetsheet_setting.value.nil?
      budgetsheet_setting.value = budgetsheet_setting.value + EasyMoneyRateType.active.collect{|r| (EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + r.name)}
      budgetsheet_setting.save!
    end
  end

  def self.down
    budgetsheet_setting = EasySetting.find_by_name('easy_time_entry_query_list_default_columns')
    if budgetsheet_setting && !budgetsheet_setting.value.nil?
      budgetsheet_setting.value = budgetsheet_setting.value - EasyMoneyRateType.active.collect{|r| (EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + r.name)}
      budgetsheet_setting.save!
    end    
  end
end
