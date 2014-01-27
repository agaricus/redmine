module EasyBudgetsheet
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_time_entries_user_time_entry_middle, :partial => 'timelog/easy_budgetsheet_view_time_entries_user_time_entry_middle'
    render_on :view_time_entries_context_menu_end, :partial => 'timelog/easy_budgetsheet_view_time_entries_context_menu_end'
    render_on :view_settings_timeentries_form, :partial => 'settings/easy_budgetsheet_view_settings_timeentries_form'

  end
end