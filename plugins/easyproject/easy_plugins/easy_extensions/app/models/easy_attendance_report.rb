class EasyAttendanceReport
  attr_reader :user, :user_activities, :sum_timeentries, :from, :to

  def initialize(user, from=nil, to=nil)
    @user = user
    @to = to || EasyAttendance.reorder(:created_at).last.arrival.to_date
    @from = from || EasyAttendance.reorder(:created_at).first.arrival.to_date

    @user_activities = EasyAttendance.where(:user_id => @user.id, :arrival => @from.to_time..@to.to_time.end_of_day, :departure => @from.to_time..@to.to_time.end_of_day).all.inject({}) {|memo, var| memo[var.easy_attendance_activity_id] ||= 0; memo[var.easy_attendance_activity_id] += var.departure - var.arrival; memo}

    @sum_timeentries = TimeEntry.where(:user_id => @user.id, :spent_on => @from..@to).sum(:hours)
  end

  def sum_working_hours
    @sum_working_hours ||= @user.current_working_time_calendar.sum_working_hours(@from, @to)
  end

  def sum_attendance_hours
    @sum_attendance_hours ||= @user.current_working_time_calendar.sum_working_time(@from, @to)
  end

  def sum_attendances
    @sum_attendances ||= (@user_activities.inject(0.0){|memo, a| memo += a[1].to_f} / 1.hour)
  end

  def timeentries_percent
    @timeentries_percent ||= (sum_working_hours > 0 ? ((sum_timeentries / sum_working_hours) * 100).round(2) : 0.0)
  end

  def working_attendance_percent
    @working_attendance_percent ||= (sum_attendance_hours > 0 ? ((sum_attendances / sum_attendance_hours) * 100).round(2) : 0.0)
  end

  def working_percent
    @working_percent ||= (sum_working_hours > 0 ? ((sum_attendances / sum_working_hours) * 100).round(2) : 0.0)
  end

  def timeentries_percent_class_name
    if timeentries_percent > 110
      'positive'
    elsif timeentries_percent < 90
      'negative'
    else
      'normal'
    end
  end

  def working_percent_class_name
    if working_percent > 110
      'positive'
    elsif working_percent < 90
      'negative'
    else
      'normal'
    end
  end

end
