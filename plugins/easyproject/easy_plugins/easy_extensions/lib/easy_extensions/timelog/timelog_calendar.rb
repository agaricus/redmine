module EasyExtensions
  module Timelog
    class Calendar
      include Redmine::I18n
      attr_reader :startdt, :enddt, :period

      def initialize(date, lang = current_language, period = :month)
        @date = date
        @events = []
        @events_by_days = {}
        set_language_if_valid lang
        case period
        when :month
          @startdt = Date.civil(date.year, date.month, 1)
          @enddt = (@startdt >> 1)-1
          # starts from the first day of the week
          @startdt = @startdt - (@startdt.cwday - first_wday)%7
          # ends on the last day of the week
          @enddt = @enddt + (last_wday - @enddt.cwday)%7
        when :week
          @startdt = date - (date.cwday - first_wday)%7
          @enddt = date + (last_wday - date.cwday)%7
        else
          raise 'Invalid period'
        end
        @period = period
      end

      def events=(events)
        @events = events
        @events_by_days = @events.group_by {|event| event.spent_on}
      end

      # Returns events for the given day
      def events_on(day)
        (@events_by_days[day] || []).uniq
      end

      # Calendar current month
      def month
        @date.month
      end

      def year
        @date.year
      end

      # Return the first day of week
      # 1 = Monday ... 7 = Sunday
      def first_wday
        case Setting.start_of_week.to_i
        when 1
          @first_dow ||= (1 - 1)%7 + 1
        when 7
          @first_dow ||= (7 - 1)%7 + 1
        else
          @first_dow ||= (l(:general_first_day_of_week).to_i - 1)%7 + 1
        end
      end

      def last_wday
        @last_dow ||= (first_wday + 5)%7 + 1
      end

      def next_start_date
        @enddt + 1.day
      end

      def prev_start_date
        case @period
        when :month
          @date - 1.month
        when :week
          @date - 1.week
        else
          @date
        end
      end
    end
  end
end
