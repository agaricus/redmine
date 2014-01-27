class EasyMoneyIssue < EasyMoneyEntity

  def easy_money_settings
    @entity.project.easy_money_settings
  end

  def expected_expenses_scope(options={})
    scope = EasyMoneyExpectedExpense.where(create_sql_where(EasyMoneyExpectedExpense.table_name))
    scope = merge_scope(scope, options)
    scope
  end

  def expected_revenues_scope(options={})
    scope = EasyMoneyExpectedRevenue.where(create_sql_where(EasyMoneyExpectedRevenue.table_name))
    scope = merge_scope(scope, options)
    scope
  end

  def other_expenses_scope(options={})
    scope = EasyMoneyOtherExpense.where(create_sql_where(EasyMoneyOtherExpense.table_name))
    scope = merge_scope(scope, options)
    scope
  end

  def other_revenues_scope(options={})
    scope = EasyMoneyOtherRevenue.where(create_sql_where(EasyMoneyOtherRevenue.table_name))
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_scope(options={})
    sql_where = []
    sql_where << "EXISTS (SELECT i.id FROM #{Issue.table_name} i WHERE i.id = #{TimeEntry.table_name}.issue_id AND i.root_id = #{@entity.root_id} AND i.lft >= #{@entity.lft} AND i.rgt <= #{@entity.rgt})"
    sql_where.join(' OR ')

    scope = TimeEntry.where(sql_where)
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_expenses_scope(options={})
    sql_where = []
    sql_where << "EXISTS (SELECT t.id FROM #{TimeEntry.table_name} t INNER JOIN #{Issue.table_name} i ON i.id = t.issue_id WHERE t.id = #{EasyMoneyTimeEntryExpense.table_name}.time_entry_id AND i.root_id = #{@entity.root_id} AND i.lft >= #{@entity.lft} AND i.rgt <= #{@entity.rgt})"
    sql_where.join(' OR ')

    scope = EasyMoneyTimeEntryExpense.where(sql_where)
    scope = merge_scope(scope, options)
    scope
  end

  def expected_payroll_expenses_scope(options={})
    scope = EasyMoneyExpectedPayrollExpense.where(create_sql_where(EasyMoneyExpectedPayrollExpense.table_name))
    scope = merge_scope(scope, options)
    scope
  end

  def sum_expected_hours(options={})
    if @entity.project.module_enabled?(:time_tracking)
      @entity.estimated_hours || 0.0
    else
      0.0
    end
  end

  private

  def create_sql_where(entity_table_name)
    sql_where = []
    sql_where << "EXISTS (SELECT i.id FROM #{Issue.table_name} i WHERE i.id = #{entity_table_name}.entity_id AND #{entity_table_name}.entity_type = 'Issue' AND i.root_id = #{@entity.root_id} AND i.lft >= #{@entity.lft} AND i.rgt <= #{@entity.rgt})"
    sql_where.join(' OR ')
  end

end
