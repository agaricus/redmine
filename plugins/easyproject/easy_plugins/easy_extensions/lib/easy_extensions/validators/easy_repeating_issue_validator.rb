module EasyExtensions
  module Validators
    class EasyRepeatingIssueValidator < ActiveModel::Validator

      include ::Redmine::I18n

      def validate(record)
        repeat_settings = record.easy_repeat_settings
        number = /\A[+-]?\d+\Z/

        unless repeat_settings['period']
          record.errors[:easy_repeat_settings] << l(:error_repeat_period_missing)
        end

        if repeat_settings['period'] == 'daily'
          record.errors[:easy_repeat_settings] << l(:error_repeat_daily_option_missing) unless repeat_settings['daily_option']
          # if repeat_settings['daily_option'] == 'each' && repeat_settings['daily_each_x'].blank?
          #   record.errors[:easy_repeat_settings] << l(:error_repeat_daily_x_blank)
          # end
          if repeat_settings['daily_option'] == 'each' && !repeat_settings['daily_each_x'].to_s.match(number)
            record.errors[:easy_repeat_settings] << l(:error_repeat_daily_x_numeric)
          end
          # if repeat_settings['daily_option'] == 'work' && repeat_settings['daily_work_x'].blank?
          #   record.errors[:easy_repeat_settings] << l(:error_repeat_daily_x_blank)
          # end
          if repeat_settings['daily_option'] == 'work' && !repeat_settings['daily_work_x'].to_s.match(number)
            record.errors[:easy_repeat_settings] << l(:error_repeat_daily_x_numeric)
          end
        end

        if repeat_settings['period'] == 'monthly'
          record.errors[:easy_repeat_settings] << l(:error_repeat_monthly_option_missing) unless repeat_settings['monthly_option']
          if !repeat_settings['monthly_period'].to_s.match(number) || repeat_settings['monthly_period'].to_i < 1 || repeat_settings['monthly_period'].to_i > 12
            record.errors[:easy_repeat_settings] << l(:error_repeat_monthly_month_numeric)
          end
          if repeat_settings['monthly_option'] == 'xth'
            if !repeat_settings['monthly_day'].to_s.match(number) || repeat_settings['monthly_day'].to_i < 1 || repeat_settings['monthly_day'].to_i > 31
              record.errors[:easy_repeat_settings] << l(:error_repeat_monthly_day_numeric)
            end
          end
        end

        if repeat_settings['period'] == 'yearly'
          record.errors[:easy_repeat_settings] << l(:error_repeat_monthly_option_missing) unless repeat_settings['monthly_option']
          if !repeat_settings['yearly_period'].to_s.match(number)
            record.errors[:easy_repeat_settings] << l(:error_repeat_monthly_month_numeric)
          end
          if repeat_settings['yearly_option'] == 'date'
            if !repeat_settings['yearly_day'].to_s.match(number) || repeat_settings['yearly_day'].to_i < 1 || repeat_settings['yearly_day'].to_i > 31
              record.errors[:easy_repeat_settings] << l(:error_repeat_monthly_day_numeric)
            end
          end
        end

        if repeat_settings['period'] == 'weekly' && ( !repeat_settings['week_days'] || !repeat_settings['week_days'].any? )
          record.errors[:easy_repeat_settings] << l(:error_repeat_weekly_days_selected)
        end

        unless repeat_settings['endtype']
          record.errors[:easy_repeat_settings] << l(:error_repeat_endtype_missing)
        end
        # if repeat_settings['endtype'] == 'count' && repeat_settings['endtype_count_x'].blank?
        #   record.errors[:easy_repeat_settings] << l(:error_repeat_endtype_count_blank)
        # end

        if repeat_settings['endtype'] == 'count' && !repeat_settings['endtype_count_x'].to_s.match(number)
          record.errors[:easy_repeat_settings] << l(:error_repeat_endtype_count_numeric)
        end

        if repeat_settings['endtype'] == 'date' && repeat_settings['end_date'].blank?
          record.errors[:easy_repeat_settings] << l(:error_repeat_endtype_date_blank)
        end
      end
    end
  end
end