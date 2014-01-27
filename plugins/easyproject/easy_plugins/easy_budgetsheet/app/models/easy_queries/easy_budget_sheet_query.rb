class EasyBudgetSheetQuery < EasyTimeEntryBaseQuery

  def query_after_initialize
    super
    self.display_project_column_if_project_missing = false
    self.easy_query_entity_controller = 'budgetsheet'
  end

  def entity_scope
    if User.current.allowed_to?(:view_all_statements, nil, :global => true)
      TimeEntry.non_templates
    else
      TimeEntry.non_templates.visible_with_archived.where(:time_entries => {:user_id => User.current.id})
    end
  end

  def remove_user_column
    self.column_names = self.columns.map{|column| column.name}.delete_if{|column| column == :user}
  end

end
