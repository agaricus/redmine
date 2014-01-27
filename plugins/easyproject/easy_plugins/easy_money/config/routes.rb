match 'easy_money/project_selector', :to => 'easy_money#project_selector'
match 'easy_money/move_to_project', :to => 'easy_money#move_to_project'
match 'easy_money/projects_to_move', :to => 'easy_money#projects_to_move'

# easy_money_expected_expenses
match 'easy_money_expected_expenses/inline_edit', :controller => 'easy_money_expected_expenses', :action => 'inline_edit'
match 'easy_money_expected_expenses/inline_update', :controller => 'easy_money_expected_expenses', :action => 'inline_update'
resources :easy_money_expected_expenses

# easy_money_expected_hours
match 'easy_money_expected_hours(/:action)', :controller => 'easy_money_expected_hours'

# easy_money_expected_revenues
match 'easy_money_expected_revenues/inline_edit', :controller => 'easy_money_expected_revenues', :action => 'inline_edit'
match 'easy_money_expected_revenues/inline_update', :controller => 'easy_money_expected_revenues', :action => 'inline_update'
resources :easy_money_expected_revenues

# easy_money_other_expenses
match 'easy_money_other_expenses/inline_edit', :to => 'easy_money_other_expenses#inline_edit'
match 'easy_money_other_expenses/inline_update', :to => 'easy_money_other_expenses#inline_update'
resources :easy_money_other_expenses

# easy_money_other_revenues
match 'easy_money_other_revenues/inline_edit', :controller => 'easy_money_other_revenues', :action => 'inline_edit'
match 'easy_money_other_revenues/inline_update', :controller => 'easy_money_other_revenues', :action => 'inline_update'
resources :easy_money_other_revenues

# easy_money_queries
get 'easy_money_queries/easy_money_expected_expense_context_menu', :to => 'easy_money_queries#easy_money_expected_expense_context_menu', :as => 'easy_money_expected_expenses_context_menu'
get 'easy_money_queries/easy_money_expected_revenue_context_menu', :to => 'easy_money_queries#easy_money_expected_revenue_context_menu', :as => 'easy_money_expected_revenues_context_menu'
get 'easy_money_queries/easy_money_other_expense_context_menu', :to => 'easy_money_queries#easy_money_other_expense_context_menu', :as => 'easy_money_other_expenses_context_menu'
get 'easy_money_queries/easy_money_other_revenue_context_menu', :to => 'easy_money_queries#easy_money_other_revenue_context_menu', :as => 'easy_money_other_revenues_context_menu'

get 'easy_money_cash_flow_prediction', :to => 'easy_money_cash_flow_prediction#index'
get 'easy_money_cash_flow_history', :to => 'easy_money_cash_flow_history#index'

resources :projects do

  # easy_money
  match 'easy_money', :to => 'easy_money#project_index'
  match 'easy_money(/:action)', :controller => 'easy_money'

  # easy_money_expected_payroll_expenses
  match 'easy_money_expected_payroll_expenses(/:action)', :controller => 'easy_money_expected_payroll_expenses'

  # easy_money_rates
  match 'easy_money_rates(/:action)', :controller => 'easy_money_rates'

  # easy_money_priorities
  match 'easy_money_priorities(/:action)', :controller => 'easy_money_priorities'

  # easy_money_time_entry_expenses
  match 'easy_money_time_entry_expenses(/:action)', :controller => 'easy_money_time_entry_expenses'

  # easy_money_settings
  match 'easy_money_settings(/:action)', :controller => 'easy_money_settings'

end

match 'easy_money', :to => 'easy_money#index'
match 'easy_money/page_layout', :to => 'easy_money#index_page_layout'

# easy_money_rates
match 'easy_money_rates(/:action)', :controller => 'easy_money_rates'

# easy_money_priorities
match 'easy_money_priorities(/:action)', :controller => 'easy_money_priorities'

# easy_money_time_entry_expenses
match 'easy_money_time_entry_expenses(/:action)', :controller => 'easy_money_time_entry_expenses'

# easy_money_settings
match 'easy_money_settings(/:action)', :controller => 'easy_money_settings'

# easy_money_project_caches
get 'easy_money_project_caches', :to => 'easy_money_project_caches#index'
