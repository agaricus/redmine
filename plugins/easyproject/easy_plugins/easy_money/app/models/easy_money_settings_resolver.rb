class EasyMoneySettingsResolver

  def initialize(settings_names, project = nil)
    raise ArgumentError, 'Names cannot be blank.' if settings_names.blank?

    @settings = {}
    settings_names.each{|name| @settings[name] = EasyMoneySettings.find_settings_by_name(name, project) }
  end

  def [](name)
    @settings[name]
  end

  def show_price1?
    (@settings['price_visibility'] == 'all') || (@settings['price_visibility'] == 'price1')
  end

  def show_price2?
    (@settings['price_visibility'] == 'all') || (@settings['price_visibility'] == 'price2')
  end

  def show_rate?(rate_name)
    (@settings['rate_type'] == 'all') || (@settings['rate_type'] == rate_name)
  end

  def show_rate_internal?
    (@settings['rate_type'] == 'all') || (@settings['rate_type'] == 'internal')
  end

  def show_rate_external?
    (@settings['rate_type'] == 'all') || (@settings['rate_type'] == 'external')
  end

  def include_childs?
    @settings['include_childs'] == '1'
  end

  def show_expected?
    @settings['expected_visibility'] == '1'
  end

  def revenues_type
    @settings['revenues_type'] || 'list'
  end

  def expenses_type
    @settings['expenses_type'] || 'list'
  end

  def expected_payroll_expense_type
    @settings['expected_payroll_expense_type'] || 'amount'
  end

  def expected_payroll_expense_rate
    @settings['expected_payroll_expense_rate'] || '0'
  end

  def expected_count_price
    @settings['expected_count_price'] || 'price1'
  end

  def expected_rate_type
    @settings['expected_rate_type'] || 'internal'
  end

  def vat
    @settings['vat']
  end
  
  def vat_disabled?
    false
  end

  def use_easy_money_for_versions?
    @settings['use_easy_money_for_versions'] == '1'
  end
  
  def use_easy_money_for_issues?
    @settings['use_easy_money_for_issues'] == '1'
  end

  def round_on_list?
    @settings['round_on_list'] == '1' || true
  end

end