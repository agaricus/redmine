class EasyMoneyEntity

  attr_reader :entity

  def initialize(entity)
    raise TypeError, 'Cannot initialize this class. Use inherited childs instead.' if self.class.name == 'EasyMoneyEntity'
    raise ArgumentError, 'Entity cannot be null.' if entity.nil?

    @entity = entity
  end

  def self.allowed_entities
    ['Project', 'Issue', 'Version']
  end

  def self.compute_price1(project, price2)
    vat = project.easy_money_settings.vat.to_f
    price1 = (price2 * (vat + 100)) / 100
    price1
  end

  def self.compute_price2(project, price1)
    vat = project.easy_money_settings.vat.to_f
    price2 = (price1.to_f * 100) / (vat + 100)
    price2
  end

  def easy_money_settings
    @entity.easy_money_settings
  end

  def default_price_type
    if self.easy_money_settings && self.easy_money_settings.expected_count_price
      @default_price_type = self.easy_money_settings.expected_count_price.to_sym
    else
      @default_price_type = :price1
    end
  end

  def default_rate_type
    if self.easy_money_settings && self.easy_money_settings.expected_rate_type
      @default_rate_type = EasyMoneyRateType.active.where(:name => self.easy_money_settings.expected_rate_type).first
    end
    @default_rate_type ||= EasyMoneyRateType.active.order(:position).first
  end

  def expected_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'expected_expenses_scope\' method!'
  end

  def expected_revenues_scope(options={})
    raise NotImplementedError, 'You have to override \'expected_revenues_scope\' method!'
  end

  def other_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'other_expenses_scope\' method!'
  end

  def other_revenues_scope(options={})
    raise NotImplementedError, 'You have to override \'other_revenues_scope\' method!'
  end

  def time_entry_scope(options={})
    raise NotImplementedError, 'You have to override \'time_entry_scope\' method!'
  end

  def time_entry_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'time_entry_expenses_scope\' method!'
  end

  def expected_payroll_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'expected_payroll_expenses_scope\' method!'
  end

  #
  # EXPECTED HOURS
  #
  def sum_expected_hours(options={})
    0.0
  end

  #
  # EXPECTED PAYROLL EXPENSES
  #
  def sum_expected_payroll_expenses(options={})
    planned_hourly_rate = self.easy_money_settings['expected_payroll_expense_rate'].to_f
    case self.easy_money_settings.expected_payroll_expense_type
    when 'amount'
      expected_payroll_expenses_scope(options).sum(:price) || 0.0
    when 'hours'
      ((@entity.expected_hours && @entity.expected_hours.hours.to_f) || 0.0) * planned_hourly_rate
    when 'estimated_hours'
      self.sum_expected_hours(options) * planned_hourly_rate
    when 'planned_hours_and_rate'
      0.0 # computed in inherited class
    else
      0.0
    end
  end

  def sum_expected_payroll_expenses_on_entity(options={})
    planned_hourly_rate = self.easy_money_settings['expected_payroll_expense_rate'].to_f
    case self.easy_money_settings.expected_payroll_expense_type
    when 'amount'
      @entity.expected_payroll_expenses.nil? ? 0.0 : (@entity.expected_payroll_expenses.price || 0.0)
    when 'hours'
      ((@entity.expected_hours && @entity.expected_hours.hours.to_f) || 0.0) * planned_hourly_rate
    when 'estimated_hours'
      self.sum_expected_hours(options) * planned_hourly_rate
    when 'planned_hours_and_rate'
      0.0 # computed in inherited class
    else
      0.0
    end
  end

  #
  # EXPECTED EXPENSES
  #
  def sum_expected_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type
    expected_expenses_scope(options).sum(price_type) || 0.0
  end

  def sum_expected_expenses_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.expected_expenses.sum(price_type) || 0.0
  end

  #
  # EXPECTED REVENUES
  #
  def sum_expected_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type
    expected_revenues_scope(options).sum(price_type) || 0.0
  end

  def sum_expected_revenues_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.expected_revenues.sum(price_type) || 0.0
  end

  #
  # OTHER EXPENSES
  #
  def sum_other_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type
    other_expenses_scope(options).sum(price_type) || 0.0
  end

  def sum_other_expenses_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.other_expenses.sum(price_type) || 0.0
  end

  #
  # OTHER REVENUES
  #
  def sum_other_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type
    other_revenues_scope(options).sum(price_type) || 0.0
  end

  def sum_other_revenues_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.other_revenues.sum(price_type) || 0.0
  end

  #
  # TIME ENTRY EXPENSES
  #
  def sum_time_entry_expenses(rate_type=nil, options={})
    rate_type ||= self.default_rate_type
    time_entry_expenses_scope(options).easy_money_time_entries_by_rate_type(rate_type).sum(:price) || 0.0
  end

  #
  # TIME ENTRY HOURS
  #
  def sum_time_entry_hours(options={})
    time_entry_scope(options).sum(:hours) || 0.0
  end

  #
  # SUMS
  #
  def sum_all_expected_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_expected_revenues(price_type, options)
  end

  def sum_all_expected_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_expected_expenses(price_type, options) + sum_expected_payroll_expenses(options)
  end

  def sum_all_other_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_other_revenues(price_type, options)
  end

  def sum_all_other_expenses(price_type=nil, rate_type=nil, options={})
    price_type ||= self.default_price_type
    rate_type ||= self.default_rate_type

    sum_other_expenses(price_type, options) + sum_time_entry_expenses(rate_type, options)
  end

  #
  # PROFIT
  #
  def expected_profit(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_all_expected_revenues(price_type, options) - sum_all_expected_expenses(price_type, options)
  end

  def other_profit(price_type=nil, rate_type=nil, options={})
    price_type ||= self.default_price_type
    rate_type ||= self.default_rate_type

    sum_all_other_revenues(price_type, options) - sum_all_other_expenses(price_type, rate_type, options)
  end

  #
  # AVERAGE HOURLY RATE
  #
  def average_hourly_rate(price_type=nil, options={})
    price_type ||= self.default_price_type

    sor = sum_other_revenues(price_type, options)
    soe = sum_other_expenses(price_type, options)
    steh = self.sum_time_entry_hours(options)

    if steh > 0.0
      (sor - soe) / steh
    else
      0.0
    end
  end

  private

  def merge_scope(scope, options={})
    options ||= {}
    options[:scope] ||= {}

    scope = scope.where(options[:scope][:where]) if options[:scope][:where]
    scope = scope.includes(options[:scope][:includes]) if options[:scope][:includes]
    scope = scope.joins(options[:scope][:joins]) if options[:scope][:joins]
    scope = scope.order(options[:scope][:order]) if options[:scope][:order]
    scope = scope.limit(options[:scope][:limit]) if options[:scope][:limit]
    scope = scope.offset(options[:scope][:offset]) if options[:scope][:offset]

    scope
  end

end
