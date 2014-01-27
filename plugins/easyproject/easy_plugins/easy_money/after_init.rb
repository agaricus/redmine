Dir[File.dirname(__FILE__) + '/lib/easy_money/redmine/helpers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/redmine/models/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/redmine/others/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/easy_extensions/controllers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/easy_extensions/helpers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/easy_budgetsheet/models/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/easy_printable_templates/helpers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_money/easy_xml_data/importables/*.rb'].each {|file| require_dependency file }

ActionDispatch::Reloader.to_prepare do

  Redmine::AccessControl.map do |map|
    map.project_module :easy_money do |pmap|

      pmap.permission :view_easy_money, { :easy_money => [:project_index, :index], :easy_money_project_caches => :index }, :read => true

      pmap.permission :easy_money_show_expected_revenue, {:easy_money_expected_revenues => [:index, :show] }, :read => true

      pmap.permission :easy_money_manage_expected_revenue, {
        :easy_money_expected_revenues => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update]
      }, :read => true

      pmap.permission :easy_money_show_expected_expense, { :easy_money_expected_expenses => [:index, :show] }, :read => true

      pmap.permission :easy_money_manage_expected_expense, {
        :easy_money_expected_expenses => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update]
      }

      pmap.permission :easy_money_show_expected_payroll_expense, {
        :easy_money_expected_payroll_expenses => [:inline_edit],
        :easy_money_expected_hours => [:inline_edit]
      }, :read => true

      pmap.permission :easy_money_manage_expected_payroll_expense, {
        :easy_money_expected_payroll_expenses => [:inline_edit, :inline_update, :inline_expected_payroll_expenses],
        :easy_money_expected_hours => [:inline_edit, :inline_update],
      }

      pmap.permission :easy_money_show_expected_profit, { :easy_money => [:inline_expected_profit] }, :read => true

      pmap.permission :easy_money_show_other_revenue, { :easy_money_other_revenues => [:index, :show] }, :read => true

      pmap.permission :easy_money_manage_other_revenue, {
        :easy_money_other_revenues => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update],
      }

      pmap.permission :easy_money_show_time_entry_expenses, { :easy_money_time_entry_expenses => [:index]}, :read => true

      pmap.permission :easy_money_show_other_expense, { :easy_money_other_expenses => [:index, :show], :easy_money_queries => [:easy_money_other_expense] }, :read => true

      pmap.permission :easy_money_manage_other_expense, {
        :easy_money_other_expenses => [:index, :show, :new, :create, :edit, :update, :destroy, :inline_edit, :inline_update]
      }

      pmap.permission :easy_money_show_other_profit, { :easy_money => [:inline_other_profit] }, :read => true

      pmap.permission :easy_money_settings, {
        :easy_money_settings => [:project_settings, :move_rate_priority, :update_settings, :recalculate, :easy_money_rate_priorities],
        :easy_money_time_entry_expenses => [:update_project_time_entry_expenses, :update_all_projects_time_entry_expenses, :update_project_and_subprojects_time_entry_expenses],
        :easy_money_rates => [:update_rates, :update_rates_to_projects, :update_rates_to_subprojects, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users],
        :easy_money_priorities => [:update_priorities_to_projects, :update_priorities_to_subprojects]
      }

      pmap.permission :easy_money_move, {:easy_money => :move}

      pmap.permission :easy_money_cash_flow_prediction, { :easy_money_cash_flow_prediction => [:index] }, :global => true
      pmap.permission :easy_money_cash_flow_history, { :easy_money_cash_flow_history => [:index] }, :global => true

    end
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_money, { :controller => 'easy_money_settings', :action => 'index' }, :html => { :class => "icon icon-money" }, :if => Proc.new { User.current.admin? }, :before => :settings
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_money, { :controller => 'easy_money', :action => 'project_index'}, :param => :project_id, :caption => :label_easy_money, :if => Proc.new { |p| User.current.allowed_to?(:view_easy_money, p) || User.current.admin? }
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :easy_money, {:controller => 'easy_money', :action => 'index', :project_id => nil }, :caption => :menu_easy_money, :if => Proc.new{User.current.allowed_to_globally?(:view_easy_money, {})}, :after => :easy_budgetsheet
  end

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push :easy_money, { :controller => 'easy_money_settings', :action => 'index' }, :html => { :menu_category => 'extensions', :class => "icon icon-money"  }, :if => Proc.new { User.current.admin? }, :before => :settings
  end

  if Redmine::Plugin.installed?(:easy_budgetsheet)
    Redmine::AccessControl.map do |map|
      map.project_module :easy_budgetsheet do |pmap|
        pmap.permission :easy_budgetsheet_view_internal_rates, {}, :read => true, :global => true
        pmap.permission :easy_budgetsheet_view_external_rates, {}, :read => true, :global => true
      end
    end
  end

  require 'easy_money/hooks'
end

require 'easy_money/easymoney_orphans'
EasyExtensions::Orphans.map do |orphans_mapper|
  orphans_mapper.register_plugin EasyExtensions::EasyMoneyOrphans.new
end

EasyQuery.map do |query|
  query.register EasyMoneyExpectedExpenseQuery
  query.register EasyMoneyExpectedRevenueQuery
  query.register EasyMoneyOtherExpenseQuery
  query.register EasyMoneyOtherRevenueQuery
  query.register EasyMoneyProjectCacheQuery
end
