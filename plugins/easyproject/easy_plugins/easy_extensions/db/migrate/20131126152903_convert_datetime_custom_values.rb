class ConvertDatetimeCustomValues < ActiveRecord::Migration
  def up
    custom_values = CustomValue.joins(:custom_field).where(:custom_fields => {:field_format => :datetime})

    say("Converting #{custom_values.count} datetime CustomValues")

    custom_values.each do |cv|
      value = cv.value
      if value.is_a?(String)
        v = begin; YAML.load(value); rescue; nil; end
        if v.is_a?(Hash)
          value = v
          if value['date'].blank?
            value = nil
          else
            value = begin
              d = value['date'].to_date
               Time.new(d.year,d.month,d.day, value['hour'], value['minute'])
            rescue
            end
          end
          cv.update_column(:value, value)
        end
      end
    end
  end

  def down
  end
end
