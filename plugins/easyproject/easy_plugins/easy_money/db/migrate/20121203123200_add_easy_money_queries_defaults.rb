class AddEasyMoneyQueriesDefaults < ActiveRecord::Migration
  def self.up

    EasySetting.create(:name => 'easy_money_other_revenue_query_list_default_columns', :value => ['project', 'spent_on', 'name', 'price1'])
    EasySetting.create(:name => 'easy_money_other_expense_query_list_default_columns', :value => ['project', 'spent_on', 'name', 'price1'])
    EasySetting.create(:name => 'easy_money_expected_revenue_query_list_default_columns', :value => ['project', 'spent_on', 'name', 'price1'])
    EasySetting.create(:name => 'easy_money_expected_expense_query_list_default_columns', :value => ['project', 'spent_on', 'name', 'price1'])

  end

  def self.down

    EasySetting.where(:name => 'easy_money_other_revenue_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_money_other_expense_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_money_expected_revenue_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_money_expected_expense_query_list_default_columns').destroy_all
    
  end
end