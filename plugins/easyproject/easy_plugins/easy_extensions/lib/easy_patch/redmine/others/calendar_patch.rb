module EasyPatch
  module CalendarPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        attr_reader :startdt, :enddt, :period

        alias_method_chain :initialize, :easy_extensions
        alias_method_chain :events=, :easy_extensions

        # Calendar current month
        def month
          @date.month
        end

        def year
          @date.year
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

        def sorted_events_on( day )
          if @sort_block.nil?
            events_on( day )
          else
            res = events_on( day ).sort(&@sort_block)
            res
          end
        end

        def sort_block(&block)
          @sort_block = block
        end

        class << self
        end
      end
    end

    module InstanceMethods

      def initialize_with_easy_extensions(date, lang = current_language, period = :month)
        initialize_without_easy_extensions(date, lang, period)
        @period = period
      end

      # Sets calendar events
      def events_with_easy_extensions=(events)
        @events = events
        @ending_events_by_days = @events.group_by {|event| begin; event.due_date && event.due_date.to_date rescue nil end}
        @starting_events_by_days = @events.group_by {|event| begin; event.start_date && event.start_date.to_date rescue nil end}
      end

    end

    module ClassMethods
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Helpers::Calendar', 'EasyPatch::CalendarPatch'
