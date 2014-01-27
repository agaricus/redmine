class EasyAttendanceUserArrivalNotify < ActiveRecord::Base

  belongs_to :user
  belongs_to :notify_to, :class_name => 'User'

  def message
    m = super

    if m.blank?
      m =I18n.t(:text_easy_attendance_user_notify_default_message)
    end

    return m
  end

  def send_notify!
    EasyMailer.easy_attendance_user_arrival_notify(self).deliver
    self.destroy
  end

end