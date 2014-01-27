class EasyMoneyProjectCache < ActiveRecord::Base

  belongs_to :project

  def parent_project
    @parent_project ||= self.project.parent || self.project
  end

  def main_project
    @main_project ||= self.project.root || self.project
  end

  def update_from_project!(p, options={})
    return unless p.is_a?(Project)

    options ||= {}
    options[:only_self] = true unless options.key?(:only_self)

    self.project_id = p.id

    if p.easy_money
      rate_type_internal = EasyMoneyRateType.active.where(:name => 'internal').first
      rate_type_external = EasyMoneyRateType.active.where(:name => 'external').first

      self.sum_of_expected_hours = p.easy_money.sum_expected_hours(options)
      self.sum_of_expected_payroll_expenses = p.easy_money.sum_expected_payroll_expenses(options)

      self.sum_of_expected_expenses_price_1 = p.easy_money.sum_expected_expenses(:price1, options)
      self.sum_of_expected_revenues_price_1 = p.easy_money.sum_expected_revenues(:price1, options)
      self.sum_of_other_expenses_price_1 = p.easy_money.sum_other_expenses(:price1, options)
      self.sum_of_other_revenues_price_1 = p.easy_money.sum_other_revenues(:price1, options)

      self.sum_of_expected_expenses_price_2 = p.easy_money.sum_expected_expenses(:price2, options)
      self.sum_of_expected_revenues_price_2 = p.easy_money.sum_expected_revenues(:price2, options)
      self.sum_of_other_expenses_price_2 = p.easy_money.sum_other_expenses(:price2, options)
      self.sum_of_other_revenues_price_2 = p.easy_money.sum_other_revenues(:price2, options)

      self.sum_of_time_entries_expenses_internal = p.easy_money.sum_time_entry_expenses(rate_type_internal, options) if rate_type_internal
      self.sum_of_time_entries_expenses_external = p.easy_money.sum_time_entry_expenses(rate_type_external, options) if rate_type_external

      self.sum_of_estimated_hours = p.issues.sum(:estimated_hours)
      self.sum_of_timeentries = p.sum_of_timeentries

      self.sum_of_all_expected_expenses_price_1 = p.easy_money.sum_all_expected_expenses(:price1, options)
      self.sum_of_all_expected_revenues_price_1 = p.easy_money.sum_all_expected_revenues(:price1, options)
      self.sum_of_all_other_revenues_price_1 = p.easy_money.sum_all_other_revenues(:price1, options)
      self.sum_of_all_expected_expenses_price_2 = p.easy_money.sum_all_expected_expenses(:price2, options)
      self.sum_of_all_expected_revenues_price_2 = p.easy_money.sum_all_expected_revenues(:price2, options)
      self.sum_of_all_other_revenues_price_2 = p.easy_money.sum_all_other_revenues(:price2, options)

      self.sum_of_all_other_expenses_price_1_internal = p.easy_money.sum_all_other_expenses(:price1, rate_type_internal, options) if rate_type_internal
      self.sum_of_all_other_expenses_price_2_internal = p.easy_money.sum_all_other_expenses(:price2, rate_type_internal, options) if rate_type_internal
      self.sum_of_all_other_expenses_price_1_external = p.easy_money.sum_all_other_expenses(:price1, rate_type_external, options) if rate_type_external
      self.sum_of_all_other_expenses_price_2_external = p.easy_money.sum_all_other_expenses(:price2, rate_type_external, options) if rate_type_external

      self.expected_profit_price_1 = p.easy_money.expected_profit(:price1, options)
      self.expected_profit_price_2 = p.easy_money.expected_profit(:price2, options)
      self.other_profit_price_1_internal = p.easy_money.other_profit(:price1, rate_type_internal, options) if rate_type_internal
      self.other_profit_price_2_internal = p.easy_money.other_profit(:price2, rate_type_internal, options) if rate_type_internal
      self.other_profit_price_1_external = p.easy_money.other_profit(:price1, rate_type_external, options) if rate_type_external
      self.other_profit_price_2_external = p.easy_money.other_profit(:price2, rate_type_external, options) if rate_type_external

      self.average_hourly_rate_price_1 = p.easy_money.average_hourly_rate(:price1, options)
      self.average_hourly_rate_price_2 = p.easy_money.average_hourly_rate(:price2, options)
    end

    self.sum_of_expected_hours ||= 0.0
    self.sum_of_expected_payroll_expenses ||= 0.0
    self.sum_of_expected_expenses_price_1 ||= 0.0
    self.sum_of_expected_revenues_price_1 ||= 0.0
    self.sum_of_other_expenses_price_1 ||= 0.0
    self.sum_of_other_revenues_price_1 ||= 0.0
    self.sum_of_expected_expenses_price_2 ||= 0.0
    self.sum_of_expected_revenues_price_2 ||= 0.0
    self.sum_of_other_expenses_price_2 ||= 0.0
    self.sum_of_other_revenues_price_2 ||= 0.0
    self.sum_of_time_entries_expenses_internal ||= 0.0
    self.sum_of_time_entries_expenses_external ||= 0.0
    self.sum_of_estimated_hours ||= 0.0
    self.sum_of_timeentries ||= 0.0
    self.sum_of_all_expected_expenses_price_1 ||= 0.0
    self.sum_of_all_expected_revenues_price_1 ||= 0.0
    self.sum_of_all_other_revenues_price_1 ||= 0.0
    self.sum_of_all_expected_expenses_price_2 ||= 0.0
    self.sum_of_all_expected_revenues_price_2 ||= 0.0
    self.sum_of_all_other_revenues_price_2 ||= 0.0
    self.sum_of_all_other_expenses_price_1_internal ||= 0.0
    self.sum_of_all_other_expenses_price_2_internal ||= 0.0
    self.sum_of_all_other_expenses_price_1_external ||= 0.0
    self.sum_of_all_other_expenses_price_2_external ||= 0.0
    self.expected_profit_price_1 ||= 0.0
    self.expected_profit_price_2 ||= 0.0
    self.other_profit_price_1_internal ||= 0.0
    self.other_profit_price_2_internal ||= 0.0
    self.other_profit_price_1_external ||= 0.0
    self.other_profit_price_2_external ||= 0.0
    self.average_hourly_rate_price_1 ||= 0.0
    self.average_hourly_rate_price_2 ||= 0.0

    self.save!
  end

end
