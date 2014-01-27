module EasyExtensions::TimeCalculations

  def beginning_of_halfyear
    beginning_of_month.change(:month => [7, 1].detect { |m| m <= self.month })
  end
  alias :at_beginning_of_halfyear :beginning_of_halfyear

  def end_of_halfyear
    beginning_of_month.change(:month => [6, 12].detect { |m| m >= self.month }).end_of_month
  end
  alias :at_end_of_halfyear :end_of_halfyear

end

class Date
  include EasyExtensions::TimeCalculations

  def next_week_day( day )
    day = day % 7
    difference = ( day - self.wday )
    difference += 7 if difference <= 0
    self + difference
  end

  def closest_week_day( days = [] )
    return self + 7 unless days.is_a?(Array) && days.any?
    days.map{|d| self.next_week_day( d ) }.min
  end

  def increase_date( count, skip_weekend = false )
    return self + count unless skip_weekend
    result = self.dup
    for i in 1..count do
        result += 1
        while (result.wday % 7 == 0) or (result.wday % 7 == 6) do
          result += 1
        end
    end
    result
  end

end

class DateTime
  include EasyExtensions::TimeCalculations
end

class Time
  include EasyExtensions::TimeCalculations
end
