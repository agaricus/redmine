module EasyPatch
  module Acts
    module Repeatable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        #expects an colums
        # => easy_is_repeating:boolean, easy_next_start:date, easy_repeat_settings:text :limit => 4294967295
        # t.text :easy_repeat_settings, :limit => 4294967295, :default => nil
        # t.boolean :easy_is_repeating
        # t.date :easy_next_start
        # => options: Hash
        # => - :default_values -> will be set to the repeated entity
        def acts_as_easy_repeatable(options = {})
          cattr_accessor :easy_repeat_options
          self.easy_repeat_options = options.dup

          attr_reader :easy_repeat_simple_repeat_end_at

          scope :easy_repeating, where( :easy_is_repeating => true )
          scope :easy_to_repeat, lambda { easy_repeating.where( %Q/(
              #{self.table_name}.easy_next_start <= ?
                OR #{self.table_name}.easy_next_start IS NULL
              )/, Date.today )
            }


          if self.respond_to?(:safe_attributes)
            safe_attributes 'easy_is_repeating'
            safe_attributes 'easy_repeat_settings'
            safe_attributes 'easy_next_start'
            safe_attributes 'easy_repeat_simple_repeat_end_at'
          end

          serialize :easy_repeat_settings, Hash

          validates_with EasyExtensions::Validators::EasyRepeatingIssueValidator, :if => :easy_is_repeating?

          before_save :set_default_repeat_options, :if => :easy_is_repeating?
          after_save :create_repeated, :if => :easy_is_repeating?

          send :include, EasyPatch::Acts::Repeatable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def set_default_repeat_options
          self.easy_repeat_settings['start_timepoint'] = Date.today if self.easy_is_repeating_changed?
          self.easy_repeat_settings['start_timepoint'] ||= Date.today
          self.easy_next_start ||= count_next_start(nil)
        end

        def create_repeated
          options = self.easy_repeat_settings

          if options['create_now'] == 'none'
            return true
          elsif options['create_now'] == 'count'
            count = options['create_now_count'].to_i
          elsif options['create_now'] == 'all'
            count = 15
          else
            return true
          end

          options.delete('create_now') #otherwise it will cycle, cuz repeat saves this record

          (0..count-1).each do |i|
            repeat if should_repeat?( self.easy_next_start || Date.today )
          end
        end

        def repeat( repeat_date = nil )

          repeat_date ||= self.easy_next_start if self.easy_next_start
          repeat_date ||= Date.today

          #issue has its own copy function and needs to move due date and start_date
          if is_a?( Issue )

            start_timepoint = self.easy_repeat_settings['start_timepoint']
            start_timepoint ||= self.easy_next_start if self.easy_next_start
            start_timepoint ||= Date.today

            time_vector = repeat_date - start_timepoint

            repeated = self.copy( {:easy_is_repeating => false, :easy_repeat_settings => nil, :easy_next_start => nil },
                      { :attachments => false, :subtasks => true, :copy_author => true } )

            repeated.due_date += time_vector if repeated.due_date
            repeated.start_date += time_vector if repeated.start_date

            self.easy_repeat_settings['start_timepoint'] = start_timepoint
          else
            repeated = self.dup
            if self.respond_to?(:custom_field_values)
              repeated.custom_field_values=self.custom_field_values.inject({}) { |mem, var| mem[var.custom_field_id.to_s] = var.value;mem }
            end
            repeated.easy_is_repeating = false
            repeated.easy_repeat_settings = nil
            repeated.easy_next_start = nil
            if self.class.easy_repeat_options[:default_values].is_a?(Hash)
              self.class.easy_repeat_options[:default_values].each do |column, value|
                repeated.send("#{column}=", value)
              end
            end
          end

          if self.class.easy_repeat_options[:before_save].is_a?(Proc)
            self.class.easy_repeat_options[:before_save].call(repeated, self)
          end

          unless repeated.save
            return false
          end

          if self.class.easy_repeat_options[:after_save].is_a?(Proc)
            self.class.easy_repeat_options[:after_save].call(repeated, self)
          end

          self.easy_repeat_settings['repeated'] = self.easy_repeat_settings['repeated'].to_i + 1
          self.easy_next_start = count_next_start( repeat_date )

          self.save
        end

        def should_repeat?( date = Date.today )
          options = self.easy_repeat_settings

          case options['endtype']
          when 'endless'
            true
          when 'count'
            options['repeated'].to_i < options['endtype_count_x'].to_i
          when 'date'
            end_date = begin; options['end_date'].to_date; rescue; nil end
            return false unless end_date
            end_date >= date
          else
            # it wouldn't repeat if someone forgot fill end count repeats
            false
          end
        end

        def count_next_start( last_start = Date.today )
          options = self.easy_repeat_settings

          case options['period']
           when 'daily'
            if last_start
              last_start.increase_date( options["daily_#{options['daily_option']}_x"].to_i, options['daily_option'] == 'work' )
            else
              Date.today
            end

           when 'weekly'
            options['week_days'] = [options['week_days']] unless options['week_days'].is_a?(Array)
            (last_start || Date.today).closest_week_day( options['week_days'].map {|d| d.to_i } )

           when 'monthly'
            next_month = last_start.months_since(options["monthly_period"].to_i).beginning_of_month if last_start
            if options['monthly_option'] == 'xth'
              next_month ||= ((Date.today.mday <= options['monthly_day'].to_i) ? Date.today : Date.today.next_month.beginning_of_month )
              return next_month + (options['monthly_day'].to_i - next_month.mday)
            end

            next_month ||= Date.today

            options['monthly_custom_order'] = options['monthly_custom_order'].to_i + 1 if options['monthly_custom_order'].to_i < 0
            wday = next_month.next_week_day( options['monthly_custom_day'].to_i ) + ( options['monthly_custom_order'].to_i - 1 ) * 7

            while wday.month != next_month.month
              wday -= 7
            end

            wday
           when 'yearly'
            if options['yearly_option'] == 'date'
              if last_start.nil?
                year = Date.today.year
                if Date.today.month > options['yearly_month'].to_i || (Date.today.month == options['yearly_month'].to_i && Date.today.day > options['yearly_day'].to_i)
                  year += 1
                end
              else
                year = last_start.year+options['yearly_period'].to_i
              end

              return Date.new(year, options['yearly_month'].to_i, options['yearly_day'].to_i ) if options['yearly_option'] == 'date'
            end

            if last_start.nil?
              year = Date.today.year
              year += 1 if Date.today.month >= options['yearly_month'].to_i
            else
              year = last_start.year+options['yearly_period'].to_i
            end

            month_begin = Date.new( year, options['yearly_custom_month'].to_i, 1 )
            options['yearly_custom_order'] = options['yearly_custom_order'].to_i + 1 if options['yearly_custom_order'].to_i < 0
            wday = month_begin.next_week_day( options['yearly_custom_day'].to_i ) + ( options['yearly_custom_order'].to_i - 1 ) * 7

            # douprava, pokud bych prekrocil na dalsi mesic
            while wday.month != month_begin.month
              wday -= 7
            end

            wday
          end
        end

        def easy_repeat_settings=(settings)
          if !settings.blank? && !self.easy_repeat_settings.blank?
            settings['start_timepoint'] = self.easy_repeat_settings['start_timepoint']
            settings['repeated'] = self.easy_repeat_settings['repeated']
            if settings['repeat_hour'] && settings['repeat_hour'].match(/^(\d\d):(\d\d)$/)
              settings['repeat_hour'] = $1
            end
          end

          if settings && settings['simple_period'].present? && settings['period'].nil?
            case settings['simple_period'].to_sym
            when :daily
              settings['daily_option'] ||= 'each'
              settings['daily_each_x'] ||= '1'
              settings['period'] = 'daily'
            when :weekly
              settings['week_days'] ||= ['0']
              settings['period'] = 'weekly'
            when :monthly, :quart_year, :half_year
              settings['monthly_option'] ||= 'xth'
              settings['monthly_day'] ||= '1'
              settings['period'] = 'monthly'
              case settings['simple_period'].to_sym
              when :monthly
                settings['monthly_period'] = 1
              when :quart_year
                settings['monthly_period'] = 3
              when :half_year
                settings['monthly_period'] = 6
              end
            when :yearly
              settings['monthly_option'] ||= 'xth'
              settings['yearly_option'] ||= 'date'
              settings['yearly_period'] ||= 1
              settings['yearly_month'] ||= 1
              settings['yearly_day'] ||= 1
              settings['period'] = 'yearly'
            end

            if settings['end_date'].present?
              settings['endtype'] = 'date'
            end
            if settings['endtype_count_x'] && settings['endtype_count_x'].to_i > 0
              settings['endtype'] = 'count'
            end

            settings['create_now'] ||= 'none'
            settings['endtype'] ||= 'endless'

            self.easy_is_repeating = true
            settings.delete('simple_period')
          end

          write_attribute(:easy_repeat_settings, settings)
        end

        def available_simple_repeatings
          [
            :daily,
            :weekly,
            :monthly,
            :quart_year,
            :half_year,
            :yearly,
            # ------
            :custom
          ]
        end

        def easy_repeat_simple_repeat_end_at=(value)
          @easy_repeat_simple_repeat_end_at = value
        end

        module ClassMethods
        end
      end

    end
  end
end
