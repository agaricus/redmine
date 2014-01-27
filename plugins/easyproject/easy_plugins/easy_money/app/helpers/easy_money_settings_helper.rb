module EasyMoneySettingsHelper

  def easy_money_settings_tabs
    [
      {:name => 'EasyMoneyExpectedExpenseCustomField', :partial => 'custom_fields/easy_money_index', :label => :tab_easy_money_expected_expense_custom_field, :no_js_link => true},
      {:name => 'EasyMoneyExpectedRevenueCustomField', :partial => 'custom_fields/easy_money_index', :label => :tab_easy_money_expected_revenue_custom_field, :no_js_link => true},
      {:name => 'EasyMoneyOtherExpenseCustomField', :partial => 'custom_fields/easy_money_index', :label => :tab_easy_money_other_expense_custom_field, :no_js_link => true},
      {:name => 'EasyMoneyOtherRevenueCustomField', :partial => 'custom_fields/easy_money_index', :label => :tab_easy_money_other_revenue_custom_field, :no_js_link => true},
      {:name => 'EasyMoneyRatePriority', :partial => 'easy_money_rate_priorities/default_priorities', :label => :tab_easy_money_rate_priorities, :no_js_link => true},
      {:name => 'EasyMoneyRateRole', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_role, :entity_type => 'Role', :no_js_link => true},
      {:name => 'EasyMoneyRateTimeEntryActivity', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_time_entry_activity, :entity_type => 'TimeEntryActivity', :no_js_link => true},
      {:name => 'EasyMoneyRateUser', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_user, :entity_type => 'User', :no_js_link => true},
      {:name => 'EasyMoneyOtherSettings', :partial => 'easy_money_settings/other_settings', :label => :tab_easy_money_other_settings, :no_js_link => true}
    ]
  end

  def easy_money_project_settings_tabs(project)
    [
      {:name => 'EasyMoneyRatePriority', :partial => 'easy_money_rate_priorities/default_priorities', :label => :tab_easy_money_rate_priorities, :project => project, :no_js_link => true},
      {:name => 'EasyMoneyRateRole', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_role, :entity_type => 'Role', :project => project, :no_js_link => true},
      {:name => 'EasyMoneyRateTimeEntryActivity', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_time_entry_activity, :entity_type => 'TimeEntryActivity', :project => project, :no_js_link => true},
      {:name => 'EasyMoneyRateUser', :partial => 'easy_money_rates/entity_index', :label => :tab_easy_money_rate_user, :entity_type => 'User', :project => project, :no_js_link => true},
      {:name => 'EasyMoneyOtherSettings', :partial => 'easy_money_settings/other_settings', :label => :tab_easy_money_other_settings, :project => project, :no_js_link => true}
    ]
  end

end
