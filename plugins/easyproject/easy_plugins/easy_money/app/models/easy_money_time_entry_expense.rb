class EasyMoneyTimeEntryExpense < ActiveRecord::Base
  self.table_name = 'easy_money_time_entries_expenses'

  belongs_to :time_entry, :class_name => "TimeEntry", :foreign_key => 'time_entry_id'
  belongs_to :rate_type, :class_name => "EasyMoneyRateType", :foreign_key => 'rate_type_id'
  has_one :project, :through => :time_entry
  has_one :issue, :through => :time_entry

  scope :easy_money_time_entries_by_rate_type, lambda {|rate_type| where("#{EasyMoneyTimeEntryExpense.table_name}.rate_type_id = #{rate_type.id}")}
  scope :easy_money_time_entries_by_time_entry_and_rate_type, lambda {|time_entry, rate_type| where("#{EasyMoneyTimeEntryExpense.table_name}.time_entry_id = #{time_entry.id} AND #{EasyMoneyTimeEntryExpense.table_name}.rate_type_id = #{rate_type.id}")}

  EASY_QUERY_PREFIX = 'easy_money_rate_type_'

  def self.update_project_time_entry_expenses(project_id)
    return if project_id.nil?

    TimeEntry.where(:project_id => project_id).includes(:project).all.each do |time_entry|
      update_easy_money_time_entry_expense(time_entry)
    end
  end

  def self.update_all_projects_time_entry_expenses(project_ids)
    return if project_ids.blank?

    project_ids.each{|pid| update_project_time_entry_expenses(pid)}
  end

  def self.update_easy_money_time_entry_expense(time_entry)
    return if !time_entry.is_a?(TimeEntry) || time_entry.new_record?

    EasyMoneyRateType.active.all.each do |rate_type|
      time_entry_expense = EasyMoneyTimeEntryExpense.easy_money_time_entries_by_time_entry_and_rate_type(time_entry, rate_type).first
      price = compute_expense(time_entry, rate_type)

      if time_entry_expense.nil?
        time_entry.easy_money_time_entry_expenses.create(:rate_type_id => rate_type.id, :price => price)
      else
        time_entry_expense.price = price
        time_entry_expense.save
      end
    end
  end

  def self.compute_expense(time_entry, rate_type)
    time_entry.hours * EasyMoneyRate.get_unit_rate_for_time_entry(time_entry, rate_type)
  end

end
