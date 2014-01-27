class EasyMoneySettings < ActiveRecord::Base
  self.table_name = 'easy_money_settings'

  belongs_to :project, :class_name => "Project", :foreign_key => 'project_id'

  validates_length_of :name, :in => 1..255, :allow_nil => false
  validates_length_of :value, :in => 0..255, :allow_nil => true

  def self.project_settings_names
    ['currency', 'currency_format', 'price_visibility', 'rate_type', 'include_childs', 'expected_visibility', 'expected_count_price',
      'expected_rate_type', 'vat', 'revenues_type', 'expenses_type', 'expected_payroll_expense_type', 'expected_payroll_expense_rate',
      'use_easy_money_for_versions', 'use_easy_money_for_issues', 'round_on_list']
  end

  def self.global_settings_names
    ['currency_visible']
  end

  def self.find_settings_by_name(name, project = nil)
    project_id = project.is_a?(Project) ? project.id : project.to_i
    scope = EasyMoneySettings.where(:name => name)

    if project_id.nil?
      scope = scope.where('project_id IS NULL')
    else
      scope = scope.where(['project_id IS NULL OR project_id = ?', project_id])
    end
    scope = scope.order('CASE WHEN project_id IS NULL THEN 0 ELSE project_id END DESC').limit(1)

    scope.pluck(:value).first
  end

  def self.copy_to(project_from, project_to)
    EasyMoneySettings.where(:project_id => project_from.id).all.each do |project_from_setting|
      setting = project_from_setting.dup
      setting.project_id = project_to.id
      setting.save
    end
  end

end
