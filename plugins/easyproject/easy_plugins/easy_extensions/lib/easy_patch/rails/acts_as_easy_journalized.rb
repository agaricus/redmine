module EasyPatch
  module ActsAsEasyJournalized

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_easy_journalized(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsEasyJournalized::EasyJournalizedMethods)

        default_options = {
          :non_journalized_columns => ['id', 'created_on', 'updated_on', 'updated_at', 'created_at'],
          :format_detail_date_columns => [],
          :format_detail_time_columns => [],
          :format_detail_reflection_columns => [],
          :format_detail_boolean_columns => [],
          :format_detail_hours_columns => []
        }

        cattr_accessor :journalized_options
        self.journalized_options = default_options.merge(options)

        send :include, EasyPatch::ActsAsEasyJournalized::EasyJournalizedMethods
      end

    end

    module EasyJournalizedMethods

      def self.included(base)
        base.class_eval do

          has_many :journals, :as => :journalized, :dependent => :destroy

        end
      end

      def init_journal(user, notes = '')
        @current_journal ||= self.journals.build(:user => user, :notes => notes)
        if new_record?
          @current_journal.notify = false
        else
          @attributes_before_change = attributes.dup
          @custom_values_before_change = {}
          self.visible_custom_field_values.each {|c| @custom_values_before_change.store c.custom_field_id, c.value }
        end
        @current_journal
      end

      private

      def create_journal
        if @current_journal
          # attributes changes
          if @attributes_before_change
            (self.class.column_names - journalized_options[:non_journalized_columns]).each {|c|
              before = @attributes_before_change[c]
              after = send(c)
              next if before == after || (before.blank? && after.blank?)
              @current_journal.details << JournalDetail.new(:property => 'attr',
                :prop_key => c,
                :old_value => before,
                :value => after)
            }
          end
          if @custom_values_before_change
            # custom fields changes
            custom_field_values.each {|c|
              before = @custom_values_before_change[c.custom_field_id]
              after = c.value
              next if before == after || (before.blank? && after.blank?)

              if before.is_a?(Array) || after.is_a?(Array)
                before = [before] unless before.is_a?(Array)
                after = [after] unless after.is_a?(Array)

                # values removed
                (before - after).reject(&:blank?).each do |value|
                  @current_journal.details << JournalDetail.new(:property => 'cf',
                    :prop_key => c.custom_field_id,
                    :old_value => value,
                    :value => nil)
                end
                # values added
                (after - before).reject(&:blank?).each do |value|
                  @current_journal.details << JournalDetail.new(:property => 'cf',
                    :prop_key => c.custom_field_id,
                    :old_value => nil,
                    :value => value)
                end
              else
                @current_journal.details << JournalDetail.new(:property => 'cf',
                  :prop_key => c.custom_field_id,
                  :old_value => before,
                  :value => after)
              end
            }
          end
          @current_journal.save
          # reset current journal
          init_journal @current_journal.user, @current_journal.notes
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsEasyJournalized'
