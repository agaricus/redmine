class EasyMoneyProjectCacheQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_money
  end

  def query_after_initialize
    super
    self.easy_query_entity_controller = 'easy_money_project_caches'
    self.display_project_column_if_project_missing = false
  end

  def all_projects
    @all_easy_money_projects ||= Project.visible.non_templates.has_module(:easy_money).select([:id, :name, :easy_level]).all
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    @available_filters = {}

    group_others = l(:label_filter_group_easy_money_project_cache_query)
    group_expenses = l(:label_filter_group_easy_money_project_cache_expenses)
    group_revenues = l(:label_filter_group_easy_money_project_cache_revenues)
    group_profit = l(:label_filter_group_easy_money_project_cache_profit)

    @available_filters['project_id'] = {:type => :list_optional, :order => 1, :values => Proc.new do
        project_values = []
        if User.current.logged?
          project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
        end
        project_values += self.all_projects_values
        project_values
      end, :group => group_others
    }

    @available_filters['sum_of_expected_hours'] = {:type => :float, :order => 10, :group => group_expenses}
    @available_filters['sum_of_expected_payroll_expenses'] = {:type => :float, :order => 11, :group => group_expenses}
    @available_filters['sum_of_expected_expenses_price_1'] = {:type => :float, :order => 12, :group => group_expenses}
    @available_filters['sum_of_expected_revenues_price_1'] = {:type => :float, :order => 13, :group => group_expenses}
    @available_filters['sum_of_other_expenses_price_1'] = {:type => :float, :order => 14, :group => group_revenues}
    @available_filters['sum_of_other_revenues_price_1'] = {:type => :float, :order => 15, :group => group_revenues}
    @available_filters['sum_of_expected_expenses_price_2'] = {:type => :float, :order => 16, :group => group_expenses}
    @available_filters['sum_of_expected_revenues_price_2'] = {:type => :float, :order => 17, :group => group_revenues}
    @available_filters['sum_of_other_expenses_price_2'] = {:type => :float, :order => 18, :group => group_expenses}
    @available_filters['sum_of_other_revenues_price_2'] = {:type => :float, :order => 19, :group => group_revenues}
    @available_filters['sum_of_time_entries_expenses_internal'] = {:type => :float, :order => 20, :group => group_expenses}
    @available_filters['sum_of_time_entries_expenses_external'] = {:type => :float, :order => 21, :group => group_expenses}
    @available_filters['sum_of_estimated_hours'] = {:type => :float, :order => 22, :name => l(:field_estimated_hours), :group => group_others}
    @available_filters['sum_of_timeentries'] = {:type => :float, :order => 23, :group => group_others}
    @available_filters['sum_of_all_expected_expenses_price_1'] = {:type => :float, :order => 24, :group => group_expenses}
    @available_filters['sum_of_all_expected_revenues_price_1'] = {:type => :float, :order => 25, :group => group_revenues}
    @available_filters['sum_of_all_other_revenues_price_1'] = {:type => :float, :order => 26, :group => group_revenues}
    @available_filters['sum_of_all_expected_expenses_price_2'] = {:type => :float, :order => 27, :group => group_expenses}
    @available_filters['sum_of_all_expected_revenues_price_2'] = {:type => :float, :order => 28, :group => group_revenues}
    @available_filters['sum_of_all_other_revenues_price_2'] = {:type => :float, :order => 29, :group => group_revenues}
    @available_filters['sum_of_all_other_expenses_price_1_internal'] = {:type => :float, :order => 30, :group => group_expenses}
    @available_filters['sum_of_all_other_expenses_price_2_internal'] = {:type => :float, :order => 31, :group => group_expenses}
    @available_filters['sum_of_all_other_expenses_price_1_external'] = {:type => :float, :order => 32, :group => group_expenses}
    @available_filters['sum_of_all_other_expenses_price_2_external'] = {:type => :float, :order => 33, :group => group_expenses}
    @available_filters['expected_profit_price_1'] = {:type => :float, :order => 34, :group => group_profit}
    @available_filters['expected_profit_price_2'] = {:type => :float, :order => 35, :group => group_profit}
    @available_filters['other_profit_price_1_internal'] = {:type => :float, :order => 36, :group => group_profit}
    @available_filters['other_profit_price_2_internal'] = {:type => :float, :order => 37, :group => group_profit}
    @available_filters['other_profit_price_1_external'] = {:type => :float, :order => 38, :group => group_profit}
    @available_filters['other_profit_price_2_external'] = {:type => :float, :order => 39, :group => group_profit}
    @available_filters['average_hourly_rate_price_1'] = {:type => :float, :order => 40, :group => group_others}
    @available_filters['average_hourly_rate_price_2'] = {:type => :float, :order => 41, :group => group_others}

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:parent_project, :sortable => "#{Project.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:main_project, :sortable => "#{Project.table_name}.name", :groupable => true),

        EasyQueryColumn.new(:sum_of_expected_hours, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_hours"),
        EasyQueryColumn.new(:sum_of_expected_payroll_expenses, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_payroll_expenses"),
        EasyQueryColumn.new(:sum_of_expected_expenses_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_expenses_price_1"),
        EasyQueryColumn.new(:sum_of_expected_revenues_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_revenues_price_1"),
        EasyQueryColumn.new(:sum_of_other_expenses_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_expenses_price_1"),
        EasyQueryColumn.new(:sum_of_other_revenues_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_revenues_price_1"),
        EasyQueryColumn.new(:sum_of_expected_expenses_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_expenses_price_2"),
        EasyQueryColumn.new(:sum_of_expected_revenues_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_expected_revenues_price_2"),
        EasyQueryColumn.new(:sum_of_other_expenses_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_expenses_price_2"),
        EasyQueryColumn.new(:sum_of_other_revenues_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_other_revenues_price_2"),
        EasyQueryColumn.new(:sum_of_time_entries_expenses_internal, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_time_entries_expenses_internal"),
        EasyQueryColumn.new(:sum_of_time_entries_expenses_external, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_time_entries_expenses_external"),
        EasyQueryColumn.new(:sum_of_estimated_hours, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_estimated_hours", :caption => :field_estimated_hours),
        EasyQueryColumn.new(:sum_of_timeentries, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_timeentries"),
        EasyQueryColumn.new(:sum_of_all_expected_expenses_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_expenses_price_1"),
        EasyQueryColumn.new(:sum_of_all_expected_revenues_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_revenues_price_1"),
        EasyQueryColumn.new(:sum_of_all_other_revenues_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_revenues_price_1"),
        EasyQueryColumn.new(:sum_of_all_expected_expenses_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_expenses_price_2"),
        EasyQueryColumn.new(:sum_of_all_expected_revenues_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_expected_revenues_price_2"),
        EasyQueryColumn.new(:sum_of_all_other_revenues_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_revenues_price_2"),
        EasyQueryColumn.new(:sum_of_all_other_expenses_price_1_internal, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_1_internal"),
        EasyQueryColumn.new(:sum_of_all_other_expenses_price_2_internal, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_2_internal"),
        EasyQueryColumn.new(:sum_of_all_other_expenses_price_1_external, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_1_external"),
        EasyQueryColumn.new(:sum_of_all_other_expenses_price_2_external, :sortable => "#{EasyMoneyProjectCache.table_name}.sum_of_all_other_expenses_price_2_external"),
        EasyQueryColumn.new(:expected_profit_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.expected_profit_price_1"),
        EasyQueryColumn.new(:expected_profit_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.expected_profit_price_2"),
        EasyQueryColumn.new(:other_profit_price_1_internal, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_1_internal"),
        EasyQueryColumn.new(:other_profit_price_2_internal, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_2_internal"),
        EasyQueryColumn.new(:other_profit_price_1_external, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_1_external"),
        EasyQueryColumn.new(:other_profit_price_2_external, :sortable => "#{EasyMoneyProjectCache.table_name}.other_profit_price_2_external"),
        EasyQueryColumn.new(:average_hourly_rate_price_1, :sortable => "#{EasyMoneyProjectCache.table_name}.average_hourly_rate_price_1"),
        EasyQueryColumn.new(:average_hourly_rate_price_2, :sortable => "#{EasyMoneyProjectCache.table_name}.average_hourly_rate_price_2"),
      ]

      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    EasyMoneyProjectCache
  end

  def entity_scope
    EasyMoneyProjectCache.includes(:project).where(Project.allowed_to_condition(User.current, :view_easy_money))
  end

  def sortable_columns
    c = super
    c['lft'] = "#{Project.table_name}.lft"
    c
  end

  def default_find_include
    [:project]
  end

  protected

  def sql_for_project_id_field(field, operator, value)
    sql_for_field(field, operator, value, Project.table_name, 'id')
  end

end
