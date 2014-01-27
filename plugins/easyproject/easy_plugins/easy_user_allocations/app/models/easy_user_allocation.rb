class EasyUserAllocation < ActiveRecord::Base

  belongs_to :user
  belongs_to :issue

  def self.keep_issue_start_dates?
    plugin_settings = Setting.plugin_easy_user_allocations
    plugin_settings.try(:value_at, 'keep_issue_start_dates') == '1'
  end

  def self.allocate_evenly?
    plugin_settings = Setting.plugin_easy_user_allocations
    plugin_settings.try(:value_at, 'allocate_evenly') == '1'
  end

  def self.allocate_from_start?
    plugin_settings = Setting.plugin_easy_user_allocations
    plugin_settings.try(:value_at, 'allocate_from_start') == '1'
  end

  def self.allocations_for_issue(issue, user, should_save=false, options={})
    custom_allocations = options[:custom_allocations] || {}
    resized = !!options[:resized]
    return [] if issue.due_date.blank? || issue.project.easy_is_easy_template?
    return zero_allocations_for_issue(issue, user, should_save, options) if issue.closed? || issue.estimated_hours.blank? || issue.estimated_hours == 0 || (issue.done_ratio && issue.done_ratio == 100)

    if self.allocate_from_start?
      custom_allocations.delete_if{|date, hours| issue.start_date && date < issue.start_date}
    else
      custom_allocations.delete_if{|date, hours| issue.due_date && date > issue.due_date}
    end

    estimated_hours = [issue.estimated_hours, 26280].min
    hours_left = estimated_hours - issue.spent_hours
    custom_hours = custom_allocations.values.sum
    auto_hours = hours_left - custom_hours

    if auto_hours < 0
      custom_hours = hours_left
      auto_hours = 0
    end

    allocations = []
    current_date = issue.due_date.dup

    if hours_left <= 0
      return [EasyUserAllocation.create(:user => user, :issue => issue, :date => current_date, :hours => 0)]
    end

    if self.allocate_evenly?
      return self.allocate_evenly(issue, user, should_save, hours_left, options)
    end

    if self.allocate_from_start? && issue.start_date
      current_date = issue.start_date.dup
      while hours_left > 0.0 do
        allocation = self.allocate_day(user, issue, current_date, hours_left, custom_hours, auto_hours, custom_allocations)
        hours_left -= allocation.hours
        if allocation.custom
          custom_hours -= allocation.hours
        else
          auto_hours -= allocation.hours
        end
        allocation.save if should_save
        allocations.push(allocation)
        current_date += 1.day
      end
    else
      while hours_left > 0.0 do
        allocation = self.allocate_day(user, issue, current_date, hours_left, custom_hours, auto_hours, custom_allocations)
        hours_left -= allocation.hours
        if allocation.custom
          custom_hours -= allocation.hours
        else
          auto_hours -= allocation.hours
        end
        allocation.save if should_save
        allocations.unshift(allocation)

        current_date -= 1.day
      end
    end

    if resized
      if issue.start_date && issue.start_date < allocations.first.date
        (allocations.first.date - 1.day).downto(issue.start_date) do |date|
          allocations.unshift(EasyUserAllocation.new(:user => user, :issue => issue, :date => date, :hours => 0, :custom => true))
        end
      end
      if issue.due_date > allocations.last.date
        (allocations.last.date + 1.day).upto(issue.due_date) do |date|
          allocations.push(EasyUserAllocation.new(:user => user, :issue => issue, :date => date, :hours => 0, :custom => true))
        end
      end
    end

    allocations
  end

  def self.zero_allocations_for_issue(issue, user, should_save=false, options={})
    return [] if issue.due_date.blank? || issue.project.easy_is_easy_template?

    alloc = EasyUserAllocation.new(
      :user => user,
      :issue => issue,
      :date => issue.due_date,
      :hours => 0,
      :custom => false
    )

    alloc.save if should_save
    return [alloc]
  end

  def self.allocate_evenly(issue, user, should_save, hours_left, options)
    custom_allocations = options[:custom_allocations] || {}
    allocations = []

    start_date = issue.start_date
    end_date = issue.due_date

    # Deal with the past: 0 allocations for past days, ignore past custom
    # allocations.
    if start_date < Date.today && end_date >= Date.today
      custom_allocations.delete_if { |date, hours| date < Date.today }
      (start_date..Date.yesterday).each do |past_date|
        allocation = EasyUserAllocation.new(
          :user => user,
          :issue => issue,
          :date => past_date,
          :hours => 0,
          :custom => false
        )
        allocation.save if should_save
        allocations << allocation
      end
      start_date = Date.today
    end

    # Deal with the rest: respect custom hours if possible, allocate
    # hours that are left evenly

    non_custom_hours = hours_left
    days_left, custom_days = 0, 0
    (start_date..end_date).each do |date|
      if custom_allocations[date]
          non_custom_hours -= custom_allocations[date]
          custom_days += 1
      elsif user.working_hours(date) > 0
        days_left += 1
      end
    end
    non_custom_hours = 0 if non_custom_hours < 0

    if non_custom_hours > 0
      if days_left == 0
        if (start_date..end_date).count - custom_days == 0
          custom_allocations[custom_allocations.keys.min] += non_custom_hours
          hours_per_day = 0
        else
          ignore_working_hours = true
          hours_per_day = non_custom_hours / ((start_date..end_date).count - custom_days)
        end
      else
        hours_per_day = non_custom_hours / days_left
      end
    else
      hours_per_day = 0
    end

    (start_date..end_date).each do |date|
      if custom_allocations[date]
        hours = [custom_allocations[date], hours_left].min
      else
        if ignore_working_hours || user.working_hours(date) > 0
          hours = hours_per_day
        else
          hours = 0
        end
      end
      hours_left -= hours
      allocation = EasyUserAllocation.new(
        :user => user,
        :issue => issue,
        :date => date,
        :hours => hours,
        :custom => !!custom_allocations[date]
      )
      allocation.save if should_save
      allocations.push(allocation)
    end

    allocations
  end

  def self.allocate_day(user, issue, date, hours_left, custom_hours, auto_hours, custom_allocations={})
    allocation = EasyUserAllocation.new(:user => user, :issue => issue, :date => date)
    user_daily_working_hours = user.working_hours(date) || 0.0
    if custom_allocations[date]
      user_daily_working_hours = custom_allocations[date]
      allocation.custom = true
    end

    hours = allocation.custom ? custom_hours : auto_hours

    allocation.hours = hours > user_daily_working_hours ? user_daily_working_hours : hours

    allocation
  end

  def self.allocate_issue(issue, user=nil, should_save=false, custom_allocations={})
    user ||= issue.assigned_to
    return unless user.is_a?(User)
    allocations_for_issue(issue, user, should_save, :custom_allocations => custom_allocations)
  end

  def self.allocate_issue!(issue, user=nil, custom_allocations={})
    EasyUserAllocation.where(:issue_id => issue).destroy_all
    allocate_issue(issue, user, true, custom_allocations)
  end

  def self.reallocate!
    EasyUserAllocation.destroy_all
    Issue.all_to_allocate.allocate!
  end

  def get_timeline_by_issues(period)
    tl = {}
    if self.allocation_timeline
      self.allocation_timeline.each do |k, val|
        val[1].each_with_index do |issue_id, i|
          unless tl[issue_id]
            tl[issue_id] = {:start => k, :end => k, :timeline => {}}
          end
          tl[issue_id][:timeline][k] = val[2][i]
          tl[issue_id][:start] = k if k < tl[issue_id][:start]
          tl[issue_id][:end] = k if k > tl[issue_id][:end]
        end
      end
    end
    tl.select{|issue_id, issue| (issue[:start] < period[:to]) && (issue[:end] > period[:from])}.to_a.sort_by{|data| data[1][:start]}
  end

end
