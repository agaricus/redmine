require 'utils/dateutils'

class EpmTimelogSimple < EasyPageModule
  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'timelog'
  end

  def permissions
    @permissions ||= [:view_time_entries]
  end

  def get_show_data(settings, user, page_context = {})
    date_range = get_date_range('1', settings['time_period'] || '7_days')
    entries = TimeEntry.find(:all,
      :conditions => ["#{TimeEntry.table_name}.user_id = ? AND #{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", user.id, date_range[:from], date_range[:to]],
      :include => [:activity, :project, {:issue => [:tracker, :status, :priority]}],
      :order => "#{TimeEntry.table_name}.spent_on DESC, #{Project.table_name}.name ASC, #{Tracker.table_name}.position ASC, #{Issue.table_name}.id ASC")
    entries_by_day = entries.group_by(&:spent_on)

    return {:entries_by_day => entries_by_day, :entries => entries, :period => (settings['time_period'] || '7_days')}
  end

end
