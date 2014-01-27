module EasyPatch
  module CustomValuePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :easy_custom_field_ratings

        attr_reader :default_value

        before_save :change_value_before_save
        after_save :set_global_rating
        before_create :set_default_value_before_create

        def self.get_next_autoincrement(custom_field, customized)
          settings = custom_field.settings || {}
          autoincrement_from, autoincrement_to = (settings['from'] && settings['from'].to_i) || 0, (settings['to'] && settings['to'].to_i) || 999

          scope = CustomValue.joins(:custom_field).where(["#{CustomValue.table_name}.custom_field_id = ?", custom_field.id]).
            where(["#{CustomField.table_name}.type = ?", custom_field.type]).
            where(["CAST(#{CustomValue.table_name}.value as decimal) BETWEEN ? AND ?", autoincrement_from, autoincrement_to])

          if custom_field.type == 'IssueCustomField' && (settings['per_project'] == '1' || settings['per_tracker'] == '1')
            scope = scope.joins("INNER JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{CustomValue.table_name}.customized_id")
            if settings['per_project'] == '1'
              scope = scope.where(["#{Issue.table_name}.project_id = ?", customized.project_id])
            end
            if settings['per_tracker'] == '1'
              scope = scope.where(["#{Issue.table_name}.tracker_id = ?", customized.tracker_id])
            end
          end

          numbers = scope.select("#{CustomValue.table_name}.value").all.collect{|c| c.value.to_i}
          next_number = autoincrement_from.upto(autoincrement_to).detect{|n| !numbers.include?(n)}

          if next_number
            return next_number
          else
            return autoincrement_from
          end
        end

        def self.get_next_formatted_autoincrement(custom_field, customized)
          autoincrementnumber = get_next_autoincrement(custom_field, customized)
          format_autoincrement(custom_field, autoincrementnumber)
        end

        def self.format_autoincrement(custom_field, autoincrementnumber)
          max_length = custom_field.min_length
          max_length = custom_field.max_length if custom_field.max_length > max_length
          sprintf("%0#{max_length}d", autoincrementnumber)
        end

        def cast_value(cf = nil)
          cf ||= self.custom_field
          cf.cast_value(self.value)
        end

        def selected_entities(release_cache = false)
          return @selected_entities if @selected_entities && !release_cache
          return [] if self.custom_field.field_format != 'easy_lookup'
          return [] if self.custom_field.settings.blank?
          return [] if !self.custom_field.settings.key?('entity_type')
          ent_class = self.custom_field.settings['entity_type'].constantize rescue nil;
          return [] if ent_class.nil?
          casted_value = self.cast_value
          return [] if casted_value.blank?
          sel_vals = self.class.where(:customized_id => self.customized_id, :customized_type => self.customized_type, :custom_field_id => self.custom_field_id)
          sel_ids = sel.vals.collect{|val| val.value }

          m = "find_#{self.custom_field.settings['entity_type'].underscore}_selected_entities"
          if respond_to?(m)
            @selected_entities = send(m, sel_ids)
          else
            @selected_entities = ent_class.where({:id => sel_ids}).all
          end

          @selected_entities
        end

        def find_user_selected_entities(selected_ids)
          User.where(:id => selected_ids).where(:status => User::STATUS_ACTIVE)
        end

        def reinitialize_value
          if self.custom_field.field_format == 'autoincrement'
            self.value = self.class.get_next_formatted_autoincrement(self.custom_field, self.customized)
          end
        end

        private

        def set_default_value_before_create
          case self.custom_field.field_format
          when 'autoincrement'
            max_length = self.custom_field.min_length
            max_length = self.custom_field.max_length if self.custom_field.max_length > max_length
            @default_value = self.class.get_next_formatted_autoincrement(self.custom_field, self.customized)
          end
        end

        def change_value_before_save
          case self.custom_field.field_format
          when 'amount'
            self.value = self.custom_field.amount_to_number(self.value).to_s
          when 'datetime'
            oldvalue = self.value.dup unless self.value.blank?
            if oldvalue && oldvalue.is_a?(Hash) && !oldvalue['date'].blank?
              self.value = ''
              self.value = begin; oldvalue['date'].to_date; rescue; nil; end
              unless self.value.nil?
                self.value = DateTime.civil_from_format(:local, self.value.year, self.value.month, self.value.day)
              end
              self.value += oldvalue['hour'].to_i.hour if self.value && !oldvalue['hour'].blank?
              self.value += oldvalue['minute'].to_i.minute if self.value && !oldvalue['minute'].blank?
            end
          when 'easy_rating'
            if self.value.is_a?(Hash) && !self.value['rating'].blank?
              rating = self.value['rating'].to_i
              rating = 0 if rating < 0
              rating = 100 if rating > 100
              easy_custom_field_ratings.build(
                :rating => rating,
                :description => self.value['description'],
                :user_id => User.current ? User.current.id : nil
              )
            end
            ratings = self.easy_custom_field_ratings.collect(&:rating)
            if ratings.blank?
              self.value = nil
            else
              self.value = (ratings.sum / ratings.length).round
            end
          end
        end

        def set_global_rating
          if self.custom_field.field_format == 'easy_rating' && self.customized
            rating_values = self.customized.custom_values.where(CustomField.table_name => {:field_format => 'easy_rating'}).includes(:custom_field).collect(&:cast_value).compact
            global_rating = self.customized.easy_global_rating || EasyGlobalRating.new(:customized => self.customized)
            global_rating_sum = rating_values.inject{|sum, x| sum + x}
            global_rating.value = global_rating_sum ? (global_rating_sum / rating_values.length) : nil
            global_rating.save
          end
        end

      end
    end

    module InstanceMethods

      def user_already_rated?
        if custom_field.field_format == 'easy_rating' && User.current
          !easy_custom_field_ratings.find(:first, :conditions => {:user_id => User.current}).blank?
        else
          false
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomValue', 'EasyPatch::CustomValuePatch'
