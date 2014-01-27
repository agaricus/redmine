class ChangeEasyTimeEntryQueryForBudgetsheet < ActiveRecord::Migration
  def self.up
    EasyQuery.where(:type => 'EasyTimeEntryQuery').update_all(:type => 'EasyBudgetSheetQuery')
    EasySetting.where(:name => 'easy_time_entry_query_list_default_columns').update_all(:name => 'easy_budget_sheet_query_list_default_columns')
    EasySetting.where(:name => 'easy_time_entry_query_grouped_by').update_all(:name => 'easy_budget_sheet_query_grouped_by')
    EasySetting.where(:name => 'easy_time_entry_query_default_filters').update_all(:name => 'easy_budget_sheet_query_default_filters')

    EasySetting.create(:name => 'easy_time_entry_query_list_default_columns', :value => ['project', 'issue', 'spent_on', 'user', 'activity', 'hours'])
    EasySetting.create(:name => 'easy_time_entry_query_default_filters', :value => {'spent_on' => {:operator => 'date_period_1', :values => {:from =>  '', :period => 'current_month', :to => ''}}})
  end

  def self.down
    EasySetting.where(:name => 'easy_time_entry_query_list_default_columns').destroy_all
  end

end