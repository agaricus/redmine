module EasyUtils
  module DateUtils

    def get_date_range(period_type = '1', period = 'all', from = '', to = '')
      @free_period = false
      ret = {:from => nil, :to => nil}

      if period_type == '1' || (period_type.nil? && !period.nil?)
        case period
        when 'all','is_null','is_not_null'

        when 'today'
          ret[:from] = ret[:to] = Date.today
        when 'yesterday'
          ret[:from] = ret[:to] = Date.today - 1
        when 'current_week'
          ret[:from] = Date.today - (Date.today.cwday - 1)%7
          ret[:to] = ret[:from] + 6
        when 'last_week'
          ret[:from] = Date.today - 7 - (Date.today.cwday - 1)%7
          ret[:to] = ret[:from] + 6
        when 'last_2_weeks'
          ret[:from] = Date.today - 14 - (Date.today.cwday - 1)%7
          ret[:to] = ret[:from] + 13
        when '7_days'
          ret[:from] = Date.today - 7
          ret[:to] = Date.today
        when 'current_month'
          ret[:from] = Date.civil(Date.today.year, Date.today.month, 1)
          ret[:to] = (ret[:from] >> 1) - 1
        when 'last30_next90'
          ret[:from] = Date.today - 30
          ret[:to] = Date.today + 90
        when 'last_month'
          ret[:from] = Date.civil(Date.today.year, Date.today.month, 1) << 1
          ret[:to] = (ret[:from] >> 1) - 1
        when '30_days'
          ret[:from] = Date.today - 30
          ret[:to] = Date.today
        when '90_days'
          ret[:from] = Date.today - 90
          ret[:to] = Date.today
        when 'current_year'
          ret[:from] = Date.civil(Date.today.year, 1, 1)
          ret[:to] = Date.civil(Date.today.year, 12, 31)
        when 'last_year'
          ret[:from] = Date.civil(Date.today.year - 1, 1, 1)
          ret[:to] = Date.civil(Date.today.year - 1, 12, 31)
          ### FUTURE ###
        when 'tomorrow'
          ret[:from] = ret[:to] = Date.tomorrow
        when 'next_week'
          ret[:from] = Date.today + 7 + (Date.today.cwday - 1)%7
          ret[:to] = ret[:from] + 6
        when 'next_5_days'
          ret[:from] = Date.today
          ret[:to] = Date.today + 5
        when 'next_7_days'
          ret[:from] = Date.today
          ret[:to] = Date.today + 7
        when 'next_10_days'
          ret[:from] = Date.today
          ret[:to] = Date.today + 10
        when 'next_30_days'
          ret[:from] = Date.today
          ret[:to] = Date.today + 30
        when 'next_90_days'
          ret[:from] = Date.today
          ret[:to] = Date.today + 90
        when 'next_month'
          ret[:from] = Date.civil(Date.today.year, Date.today.month, 1) >> 1
          ret[:to] = (ret[:from] >> 1) - 1
        when 'next_year'
          ret[:from] = Date.civil(Date.today.year + 1, 1, 1)
          ret[:to] = Date.civil(Date.today.year + 1, 12, 31)
          ### EXTENDED ###
        when 'to_today'
          ret[:from] = nil
          ret[:to] = Date.today
        when 'after_due_date'
          ret[:from] = nil
          ret[:to] = Date.yesterday
        else
          if respond_to?("hook_#{period}")
            ret = send("hook_#{period}")
          else
            Rails.logger.warn "You must add '#{period}' to 'utils/dateutils' !" if Rails.logger
          end
        end
      elsif period_type == '2' || (period_type.nil? && (!from.nil? || !to.nil?))
        begin; ret[:from] = from.to_s.to_date unless from.blank?; rescue; end
        begin; ret[:to] = to.to_s.to_date unless to.blank?; rescue; end
        @free_period = true
      end

      ret[:from], ret[:to] = ret[:to], ret[:from] if ret[:from] && ret[:to] && ret[:from] > ret[:to]
      return ret
    end

  end
end
