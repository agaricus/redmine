require_dependency 'data_sources/easy_project_contingency_fields'

module EasyReports
  module ContingencyFields

    class TimeEntryInternalRateField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'time_entry_internalrate',
            :category => 'easy_money',
            :depends_on_field => 'time_entry_id',
            :show_in_list => true
          })
      end

      def find_entity(entity_id)
        TimeEntry.find(entity_id) if entity_id.to_i > 0
      end

      def add_field_values_to_data_row(data_row)
        dependent_field_value = data_row[@data_source.fields[depends_on_field].name]
        time_entry = find_entity(dependent_field_value)

        unless time_entry.nil?
          @rate_type ||= EasyMoneyRateType.find_by_name('internal')
          data_row[self.name] = time_entry.compute_expense(@rate_type)
        end
      end

    end

    class TimeEntryExternalRateField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'time_entry_externalrate',
            :category => 'easy_money',
            :depends_on_field => 'time_entry_id',
            :show_in_list => true
          })
      end

      def find_entity(entity_id)
        TimeEntry.find(entity_id) if entity_id.to_i > 0
      end

      def add_field_values_to_data_row(data_row)
        dependent_field_value = data_row[@data_source.fields[depends_on_field].name]
        time_entry = find_entity(dependent_field_value)

        unless time_entry.nil?
          @rate_type ||= EasyMoneyRateType.find_by_name('external')
          data_row[self.name] = time_entry.compute_expense(@rate_type)
        end
      end

    end

    class EasyMoneyOtherRevenueIdField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'id',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherRevenue',
            :is_entity_holder => true,
            :sql_select => {'EasyMoneyOtherRevenue' => "#{EasyMoneyOtherRevenue.table_name}.id"}#,
          })
      end
    end

    class EasyMoneyOtherRevenueNameField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'name',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherRevenue',
            :show_in_list => true,
            :depends_on_field => 'easy_money_other_revenue_id',
            :sql_select => {'EasyMoneyOtherRevenue' => "#{EasyMoneyOtherRevenue.table_name}.name"}
          })
      end

    end

    class EasyMoneyOtherRevenuePrice1Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price1',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherRevenue',
            :show_in_list => true,
            :depends_on_field => 'easy_money_other_revenue_id',
            :sql_select => {'EasyMoneyOtherRevenue' => "#{EasyMoneyOtherRevenue.table_name}.price1"}
          })
      end

    end

    class EasyMoneyOtherRevenuePrice2Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price2',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherRevenue',
            :show_in_list => true,
            :depends_on_field => 'easy_money_other_revenue_id',
            :sql_select => {'EasyMoneyOtherRevenue' => "#{EasyMoneyOtherRevenue.table_name}.price2"}
          })
      end

    end

    class EasyMoneyOtherRevenueCustomFieldReports < EasyReports::ContingencyFields::EntityCustomFieldReports

      def initialize(data_source, custom_field)
        super(data_source, custom_field, {
            :category => 'easy_money',
            :sql_select => {
              'EasyMoneyOtherRevenue' => "(SELECT value FROM #{CustomValue.table_name} WHERE customized_type = 'EasyMoneyOtherRevenue' AND customized_id = #{EasyMoneyOtherRevenue.table_name}.id AND custom_field_id = #{custom_field.id})"
            }
          })
      end

    end

    class EasyMoneyOtherExpenseIdField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'id',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherExpense',
            :is_entity_holder => true,
            :sql_select => {'EasyMoneyOtherExpense' => "#{EasyMoneyOtherExpense.table_name}.id"}
          })
      end
    end

    class EasyMoneyOtherExpenseNameField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'name',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherExpense',
            :show_in_list => true,
            :depends_on_field => 'easy_money_other_expense_id',
            :sql_select => {'EasyMoneyOtherExpense' => "#{EasyMoneyOtherExpense.table_name}.name"}
          })
      end

    end

    class EasyMoneyOtherExpensePrice1Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price1',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherExpense',
            :show_in_list => true,
            :depends_on_field => 'easy_money_other_expense_id',
            :sql_select => {'EasyMoneyOtherExpense' => "#{EasyMoneyOtherExpense.table_name}.price1"}
          })
      end

    end

    class EasyMoneyOtherExpensePrice2Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price2',
            :category => 'easy_money',
            :entity => 'EasyMoneyOtherExpense',
            :show_in_list => true,
            :depends_on_field => 'easy_money_other_expense_id',
            :sql_select => {'EasyMoneyOtherExpense' => "#{EasyMoneyOtherExpense.table_name}.price2"}
          })
      end

    end

    class EasyMoneyOtherExpenseCustomFieldReports < EasyReports::ContingencyFields::EntityCustomFieldReports

      def initialize(data_source, custom_field)
        super(data_source, custom_field, {
            :category => 'easy_money',
            :sql_select => {
              'EasyMoneyOtherExpense' => "(SELECT value FROM #{CustomValue.table_name} WHERE customized_type = 'EasyMoneyOtherExpense' AND customized_id = #{EasyMoneyOtherExpense.table_name}.id AND custom_field_id = #{custom_field.id})"
            }
          })
      end

    end

    class ProjectExpectedHoursField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'expected_hours',
            :category => 'easy_money',
            :entity => 'Project',
            :show_in_list => true,
            :depends_on_field => 'project_id',
            :sql_select => {'Project' => "(SELECT hours FROM #{EasyMoneyExpectedHours.table_name} WHERE entity_type='Project' AND entity_id = #{Project.table_name}.id)"}
          })
      end

    end

    class ProjectExpectedPayrollExpenseField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'expected_payroll_expense',
            :category => 'easy_money',
            :entity => 'Project',
            :show_in_list => true,
            :depends_on_field => 'project_id',
            :sql_select => {'Project' => "(SELECT price FROM #{EasyMoneyExpectedPayrollExpense.table_name} WHERE entity_type='Project' AND entity_id = #{Project.table_name}.id)"}
          })
      end

    end

    class ProjectExpectedRevenueIdField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'id',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedRevenue',
            :depends_on_field => 'project_id',
            :is_entity_holder => true,
            :sql_select => {'EasyMoneyExpectedRevenue' => "#{EasyMoneyExpectedRevenue.table_name}.id"}
          })
      end

    end

    class ProjectExpectedRevenueNameField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'name',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedRevenue',
            :show_in_list => true,
            :depends_on_field => 'easy_money_expected_revenue_id',
            :sql_select => {'EasyMoneyExpectedRevenue' => "#{EasyMoneyExpectedRevenue.table_name}.name"}
          })
      end

    end

    class ProjectExpectedRevenuePrice1Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price1',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedRevenue',
            :show_in_list => true,
            :depends_on_field => 'easy_money_expected_revenue_id',
            :sql_select => {'EasyMoneyExpectedRevenue' => "#{EasyMoneyExpectedRevenue.table_name}.price1"}
          })
      end

    end

    class ProjectExpectedRevenuePrice2Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price2',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedRevenue',
            :show_in_list => true,
            :depends_on_field => 'easy_money_expected_revenue_id',
            :sql_select => {'EasyMoneyExpectedRevenue' => "#{EasyMoneyExpectedRevenue.table_name}.price2"}
          })
      end

    end

    class ProjectExpectedExpenseIdField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'id',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedExpense',
            :depends_on_field => 'project_id',
            :is_entity_holder => true,
            :sql_select => {'EasyMoneyExpectedExpense' => "#{EasyMoneyExpectedExpense.table_name}.id"}
          })
      end

    end

    class ProjectExpectedExpenseNameField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'name',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedExpense',
            :show_in_list => true,
            :depends_on_field => 'easy_money_expected_expense_id',
            :sql_select => {'EasyMoneyExpectedExpense' => "#{EasyMoneyExpectedExpense.table_name}.name"}
          })
      end

    end

    class ProjectExpectedExpensePrice1Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price1',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedExpense',
            :show_in_list => true,
            :depends_on_field => 'easy_money_expected_expense_id',
            :sql_select => {'EasyMoneyExpectedExpense' => "#{EasyMoneyExpectedExpense.table_name}.price1"}
          })
      end

    end

    class ProjectExpectedExpensePrice2Field < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'price2',
            :category => 'easy_money',
            :entity => 'EasyMoneyExpectedExpense',
            :show_in_list => true,
            :depends_on_field => 'easy_money_expected_expense_id',
            :sql_select => {'EasyMoneyExpectedExpense' => "#{EasyMoneyExpectedExpense.table_name}.price2"}
          })
      end

    end

    class ProjectRecoveryField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'project_recovery',
            :category => 'easy_money',
            :depends_on_field => 'project_id',
            :show_in_list => true,
            :sql_select => {'Project' => 
                "(((
(SELECT SUM(emor.price2) FROM #{EasyMoneyOtherRevenue.table_name} emor WHERE emor.entity_type = 'Project' AND emor.entity_id = #{Project.table_name}.id) -
(SELECT SUM(emoe.price2) FROM #{EasyMoneyOtherExpense.table_name} emoe WHERE emoe.entity_type = 'Project' AND emoe.entity_id = #{Project.table_name}.id)) /
(SELECT SUM(emer.price2) FROM #{EasyMoneyExpectedRevenue.table_name} emer WHERE emer.entity_type = 'Project' AND emer.entity_id = #{Project.table_name}.id)) * 100)"}})
      end

    end

    class ProjectTimeEntryAverageHourlyExpenseField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'project_timeentry_average_hourly_expense',
            :category => 'easy_money',
            :depends_on_field => 'project_id',
            :show_in_list => true,
          })
      end

      def find_entity(entity_id)
        Project.find(entity_id) if entity_id.to_i > 0
      end

      def add_field_values_to_data_row(data_row)
        dependent_field_value = data_row[@data_source.fields[depends_on_field].name]
        project = find_entity(dependent_field_value)

        if project.nil? || !project.module_enabled?(:easy_money)
          data_row[self.name] = 0
        else
          data_row[self.name] = project.easy_money.average_hourly_rate
        end
      end

    end

    class ProjectOtherProfitField < EasyReports::ContingencyFields::Field

      def initialize(data_source)
        super(data_source, {
            :name => 'project_other_profit',
            :category => 'easy_money',
            :depends_on_field => 'project_id',
            :show_in_list => true
          })
      end

      def find_entity(entity_id)
        Project.find(entity_id) if entity_id.to_i > 0
      end

      def add_field_values_to_data_row(data_row)
        dependent_field_value = data_row[@data_source.fields[depends_on_field].name]
        project = find_entity(dependent_field_value)

        if project.nil? || !project.module_enabled?(:easy_money)
          data_row[self.name] = 0
        else
          data_row[self.name] = project.easy_money.other_profit
        end
      end

    end


  end
end

