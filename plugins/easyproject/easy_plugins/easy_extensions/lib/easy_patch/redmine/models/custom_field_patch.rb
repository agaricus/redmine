module EasyPatch
  module CustomFieldPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        default_scope :order => :position
        default_scope lambda{ where( :disabled => false ) if column_names.include? 'disabled' }

        has_many :mapping_fields, :class_name => "CustomFieldMapping", :foreign_key => 'custom_field_id'

        serialize :settings, Hash

        acts_as_easy_translate

        before_validation :fill_missing_attributes
        after_destroy :clean_journal_details

        alias_method_chain :cast_value, :easy_extensions
        alias_method_chain :group_statement, :easy_extensions
        alias_method_chain :join_for_order_statement, :easy_extensions
        alias_method_chain :order_statement, :easy_extensions
        alias_method_chain :set_searchable, :easy_extensions
        alias_method_chain :validate_field_value_format, :easy_extensions
        alias_method_chain :value_class, :easy_extensions

        def available_form_fields
          case self.class.name.to_sym
          when :IssueCustomField
            r = [:is_required, :is_for_all, :is_filter, :searchable, :show_on_more_form]
            r.delete(:searchable) if %w(int float date bool).include?(field_format)
            r
          when :UserCustomField
            [:is_required, :is_filter, :editable, :visible]
          when :ProjectCustomField
            [:is_for_all, :is_filter, :show_on_list, :searchable, :is_required]
          when :DocumentCustomField
            [:is_required, :is_filter]
          when :TimeEntryCustomField
            [:is_required, :is_filter]
          else
            [:is_required]
          end
        end

        def amount_to_number(value, options = {})
          options.symbolize_keys!

          defaults  = I18n.translate(:'number.format', :locale => options[:locale], :raise => true) rescue {}
          currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :raise => true) rescue {}
          defaults  = defaults.merge(currency)

          unit      = (options[:unit]      || defaults[:unit]).to_s
          separator = (options[:separator] || defaults[:separator]).to_s
          delimiter = (options[:delimiter] || defaults[:delimiter]).to_s

          begin
            val = value.upcase.gsub(unit.upcase, '').gsub(delimiter, '').gsub(separator, '.').gsub(' ', '')
            Float(val.blank? ? 0 : val)
          rescue
            nil
          end
        end

        def number_is_amount?(value, options = {})
          return false if value.nil?
          return !amount_to_number(value, options).nil?
        end

        def translated_name
          if self.internal_name.blank?
            self.name
          else
            l(:"custom_field_names.#{self.internal_name}.label", :default => self.name)
          end
        end

        def join_for_order_statement_by_field_format
          m = "join_for_order_statement_by_field_format_#{field_format}".to_sym
          if respond_to?(m)
            send(m)
          else
            nil
          end
        end

        def join_for_order_statement_by_field_format_user
          "LEFT OUTER JOIN #{CustomValue.table_name} #{join_alias}" +
            " ON #{join_alias}.customized_type = '#{self.class.customized_class.base_class.name}'" +
            " AND #{join_alias}.customized_id = #{self.class.customized_class.table_name}.id" +
            " AND #{join_alias}.custom_field_id = #{id}" +
            " AND (#{visibility_by_project_condition})" +
            " AND #{join_alias}.value <> ''" +
            " AND #{join_alias}.id = (SELECT max(#{join_alias}_2.id) FROM #{CustomValue.table_name} #{join_alias}_2" +
            " WHERE #{join_alias}_2.customized_type = #{join_alias}.customized_type" +
            " AND #{join_alias}_2.customized_id = #{join_alias}.customized_id" +
            " AND #{join_alias}_2.custom_field_id = #{join_alias}.custom_field_id)" +
            " LEFT OUTER JOIN #{value_class.table_name} #{value_join_alias}" +
            " ON CAST(CASE #{join_alias}.value WHEN '' THEN '0' ELSE #{join_alias}.value END AS decimal(30,0)) = #{value_join_alias}.id"
        end

        def join_for_order_statement_by_field_format_version
          join_for_order_statement_by_field_format_user
        end

        def join_for_order_statement_by_field_format_int
          "LEFT OUTER JOIN #{CustomValue.table_name} #{join_alias}" +
            " ON #{join_alias}.customized_type = '#{self.class.customized_class.base_class.name}'" +
            " AND #{join_alias}.customized_id = #{self.class.customized_class.table_name}.id" +
            " AND #{join_alias}.custom_field_id = #{id}" +
            " AND (#{visibility_by_project_condition})" +
            " AND #{join_alias}.value <> ''" +
            " AND #{join_alias}.id = (SELECT max(#{join_alias}_2.id) FROM #{CustomValue.table_name} #{join_alias}_2" +
            " WHERE #{join_alias}_2.customized_type = #{join_alias}.customized_type" +
            " AND #{join_alias}_2.customized_id = #{join_alias}.customized_id" +
            " AND #{join_alias}_2.custom_field_id = #{join_alias}.custom_field_id)"
        end

        def join_for_order_statement_by_field_format_float
          join_for_order_statement_by_field_format_int
        end

        def join_for_order_statement_by_field_format_amount
          join_for_order_statement_by_field_format_int
        end

        def join_for_order_statement_by_field_format_string
          "LEFT OUTER JOIN #{CustomValue.table_name} #{join_alias}" +
            " ON #{join_alias}.customized_type = '#{self.class.customized_class.base_class.name}'" +
            " AND #{join_alias}.customized_id = #{self.class.customized_class.table_name}.id" +
            " AND #{join_alias}.custom_field_id = #{id}" +
            " AND (#{visibility_by_project_condition})" +
            " AND #{join_alias}.id = (SELECT max(#{join_alias}_2.id) FROM #{CustomValue.table_name} #{join_alias}_2" +
            " WHERE #{join_alias}_2.customized_type = #{join_alias}.customized_type" +
            " AND #{join_alias}_2.customized_id = #{join_alias}.customized_id" +
            " AND #{join_alias}_2.custom_field_id = #{join_alias}.custom_field_id)"
        end

        def join_for_order_statement_by_field_format_text
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_list
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_date
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_bool
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_autoincrement
          join_for_order_statement_by_field_format_int
        end

        def join_for_order_statement_by_field_format_datetime
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_easy_lookup
          join_for_order_statement_by_field_format_user
        end

        def join_for_order_statement_by_field_format_easy_rating
          join_for_order_statement_by_field_format_int
        end

        def join_for_order_statement_by_field_format_email
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_easy_google_map_address
          join_for_order_statement_by_field_format_string
        end

        def join_for_order_statement_by_field_format_url
          join_for_order_statement_by_field_format_string
        end

        def summable?
          summable_formats.include?(self.field_format)
        end

        def summable_sql
          case field_format
          when 'float'
            "CAST(CASE #{join_alias}.value WHEN '' THEN '0' ELSE #{join_alias}.value END AS decimal(30,3))"
          else
            group_statement
          end
        end

        private

        def fill_missing_attributes
          self.min_length ||= 0
          self.max_length ||= 0
        end

        def clean_journal_details
          JournalDetail.where(:property => 'cf', :prop_key => self.id.to_s).delete_all
        end

        def summable_formats
          ['int', 'float', 'amount']
        end

      end
    end

    module InstanceMethods

      def set_searchable_with_easy_extensions
        multiple_before = self.multiple
        result = set_searchable_without_easy_extensions
        self.multiple = multiple_before if field_format == 'easy_lookup'
        result
      end

      def cast_value_with_easy_extensions(value)
        casted = nil
        unless value.blank?
          casted = case field_format
          when 'amount'
            value.to_f
          when 'easy_lookup'
            value
          when 'datetime'
            if value.is_a?(String)
              v = begin; YAML.load(value); rescue; nil; end
              if v.is_a?(Hash)
                value = v
              end
            end
            if value.is_a?(Time)
              value
            elsif value.is_a?(String)
              begin; value.to_time(:local); rescue; nil; end;
            elsif value.is_a?(Hash) && !value['date'].blank?
              begin
                d = value['date'].to_date
                Time.new(d.year,d.month,d.day, value['hour'], value['minute'])
              rescue
              end
            else
              nil
            end
          when 'easy_rating'
            value.is_a?(Hash) ? value['rating'].to_i : value.to_i
          when 'email', 'url'
            casted = value
          else
            cast_value_without_easy_extensions(value)
          end
        end
        casted
      end

      def star_no
        return nil if field_format != 'easy_rating'
        if settings.is_a?(Hash) && (no = settings['star_no'].to_i) && no > 1 && no < 11
          settings['star_no'].to_i
        else
          5
        end
      end

      def order_statement_with_easy_extensions
        case field_format
        when 'amount'
          # Make the database cast values into numeric
          # Postgresql will raise an error if a value can not be casted!
          # CustomValue validations should ensure that it doesn't occur
          "CAST(CASE #{join_alias}.value WHEN '' THEN '0' ELSE #{join_alias}.value END AS decimal(30,3))"
        else
          order_statement_without_easy_extensions
        end
      end

      def group_statement_with_easy_extensions
        return nil if multiple?
        case field_format
        when 'amount'
          order_statement
        else
          group_statement_without_easy_extensions
        end
      end

      def join_for_order_statement_with_easy_extensions
        join_for_order_statement_by_field_format
      end

      def validate_field_value_format_with_easy_extensions(value)
        errs = validate_field_value_format_without_easy_extensions(value)
        if value.present?
          case field_format
          when 'amount'
            errs << ::I18n.t('activerecord.errors.messages.not_a_amount') unless number_is_amount?(value)
          when 'datetime'
            errs << ::I18n.t('activerecord.errors.messages.blank') if self.is_required? && value.blank?
          end
        end
        errs
      end

      def value_class_with_easy_extensions
        case field_format
        when 'easy_lookup'
          if settings.is_a?(Hash) && !settings['entity_type'].blank?
            settings['entity_type'].constantize
          else
            nil
          end
        else
          value_class_without_easy_extensions
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'CustomField', 'EasyPatch::CustomFieldPatch', :before => EasyExtensions::REDMINE_CUSTOM_FIELDS
