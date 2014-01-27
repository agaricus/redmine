module EasyExtensions::TimeRounding

  def round_min_to(minutes)
    return self if (self.min % minutes) == 0
    how_many_in_hours = (60 / minutes.round)
    how_many_in_hours.times.each do |x|
      if self.min < (rounded_min = (x + 1) * minutes.round)
        return self + (rounded_min - self.min) * 60
      end
    end
  end

  def round_min_to_quarters
    round_min_to(15)
  end

end

class DateTime
  include EasyExtensions::TimeRounding
end

class Time
  include EasyExtensions::TimeRounding
end
