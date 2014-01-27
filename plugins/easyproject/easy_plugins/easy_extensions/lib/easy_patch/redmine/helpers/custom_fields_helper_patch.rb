module EasyPatch
  module CustomFieldsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :custom_fields_tabs, :easy_extensions
        alias_method_chain :custom_field_tag_with_label, :easy_extensions
        alias_method_chain :custom_field_tag, :easy_extensions
        alias_method_chain :custom_field_tag_for_bulk_edit, :easy_extensions
        alias_method_chain :custom_field_label_tag, :easy_extensions
        alias_method_chain :show_value, :easy_extensions
        alias_method_chain :render_api_custom_values, :easy_extensions

        def easy_lookup_entity_options(type)
          EasyExtensions::EasyLookups::EasyLookup.available_lookups_by_type(type).collect{|l| [l.translated_name, l.entity_name]}.sort_by{|c| c[0]}
        end

        def easy_lookup_entity_attributes_options(entity_type)
          lookup = EasyExtensions::EasyLookups::EasyLookup.available_lookup_by_entity_name(entity_type)
          lookup.nil? ? [] : lookup.attributes
        end

        def format_custom_field_value(custom_value, options = {})
          custom_field_value ||= custom_value
          return ''.html_safe if custom_field_value.nil? || !custom_field_value.is_a?(CustomFieldValue)

          no_html = options.delete(:no_html)
          custom_field = custom_field_value.custom_field
          field_format = custom_field.field_format

          format_field_value_options = options.delete(field_format.to_sym)
          format_field_value_options ||= {}
          format_field_value_options[:no_html] = true if no_html

          if !custom_field.internal_name.blank? &&
              (format_field_value_method = "format_custom_field_#{custom_field.internal_name.underscore}_value".to_sym) &&
              respond_to?(format_field_value_method)
            content = send(format_field_value_method, custom_field_value, format_field_value_options)
          elsif (format_field_value_method = "format_#{custom_field.field_format}_value".to_sym) && respond_to?(format_field_value_method)
            content = send(format_field_value_method, custom_field_value, format_field_value_options)
          else
            content = format_value(custom_field_value.value, field_format)
          end

          if no_html
            content || ''
          else
            content_tag(:span,
              (content || '').html_safe,
              :class => "formatted-custom-value cf-#{custom_field.field_format.to_s.dasherize}")
          end
        end

        # CUSTOM FIELD TAGS
        #
        # => "custom field type"_field_tag(custom_field, custom_value, field_name, field_id, options = {})

        def date_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          tag_id = sanitize_to_id(field_id)
          (text_field_tag(field_name, custom_value.value, {:id => tag_id, :size => 10}.merge(options)) + calendar_for(tag_id)).html_safe
        end

        def datetime_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          s = ''
          tag_id = sanitize_to_id(field_id)
          selected_datetime = custom_field.cast_value(custom_value.value)
          s << '<span class="datetime-cf-container">'
          s << '<span class="cf-datetime-date">'
          s << text_field_tag(field_name + '[date]', selected_datetime && selected_datetime.to_date, {:id => (tag_id + '_date'), :size => 10}.merge(options))
          s << calendar_for((tag_id + '_date'))
          s << '</span><span class="cf-datetime-time">'
          s << select_tag(field_name + '[hour]', options_for_select(24.times.collect{|i| [i+1, i+1]}, :selected => selected_datetime && selected_datetime.hour), :id => (tag_id + '_hour'), :class => 'datetime-custom-field-tag-hour')
          s << l(:label_datetime_custom_field_tag_hour)
          s << select_tag(field_name + '[minute]', options_for_select([['00', '00'], ['15', '15'], ['30', '30'], ['45', '45']], :selected => selected_datetime && selected_datetime.min.to_s), :id => (tag_id + '_minute'), :class => 'datetime-custom-field-tag-minute')
          s << l(:label_datetime_custom_field_tag_minute)
          s << '</span>'
          s.html_safe
        end

        def text_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          (text_area_tag(field_name, custom_value.value, {:id => field_id, :rows => 3, :style => 'width:90%'}.merge(options)) + wikitoolbar_for(field_id)).html_safe
        end

        def email_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          email_field_tag(field_name, custom_value.value, {:id => field_id, :rows => 3}.merge(options))
        end

        def external_mails_custom_field_tag(custom_field, custom_value, field_name, field_id, options={})
          m = field_name.match(/^([^\[]+)\[\z*/)
          if m && name = m[1]
            tags = email_custom_field_tag(custom_field, custom_value, field_name, field_id, options) + content_tag(:br)
            tags << label_tag("#{name}_send_to_external_mails", l(:field_send_to_external_mails))
            tags << check_box_tag("#{name}[send_to_external_mails]", true, false)

            return tags.html_safe
          end
        end

        def url_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          url_field_tag(field_name, custom_value.value, {:id => field_id, :rows => 3}.merge(options))
        end

        def bool_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          hidden_field_tag(field_name, '0', :id => '') + check_box_tag(field_name, '1', custom_value.true?, {:id => field_id}.merge(options))
        end

        def list_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          blank_option = ''.html_safe
          unless custom_field.multiple?
            if custom_field.is_required?
              unless custom_field.default_value.present?
                blank_option = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '')
              end
            else
              blank_option = content_tag('option')
            end
          end
          s = select_tag(field_name, blank_option + options_for_select(custom_field.possible_values_options(custom_value.customized), custom_value.value), {:multiple => custom_field.multiple?, :id => field_id}.merge(options))
          if custom_field.multiple?
            s << hidden_field_tag(field_name, '')
          end
          s
        end

        def amount_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          text_field_tag(field_name, number_to_currency(custom_value.value), {:id => field_id}.merge(options))
        end

        def easy_lookup_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          values = params.value_from_nested_key(field_name)
          if values.blank?
            values = custom_value.value
          end

          values = [values] unless values.is_a?(Array)

          settings = custom_field.settings
          entity_class = begin; settings['entity_type'].constantize ; rescue nil; end
          if settings['entity_attribute'].start_with?('link_with_')
            attribute = EasyEntityAttribute.new(settings['entity_attribute'].sub('link_with_', ''))
          else
            attribute = EasyEntityAttribute.new(settings['entity_attribute'], {:no_link => true})
          end

          selected_values = {}
          if entity_class && values.any?
            entities = entity_class.where( :id => values ).all
            values.each do |id|
              next unless entity = entities.detect{|e| e.id == id.to_i }
              selected_values[id] = (format_html_entity_attribute(entity_class, settings['entity_attribute'], attribute.value(entity), {:entity => entity}) || '').to_str
            end
          end

          options[:multiple] ||= custom_field.multiple? ? '1' : '0'
          entity_type = custom_field.settings['entity_type']
          entity_attribute = custom_field.settings['entity_attribute']
          easy_modal_selector_field_tag(entity_type, entity_attribute, field_name, field_id, selected_values, options)
        end

        def easy_rating_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          sn = custom_field.star_no
          s = ''
          if custom_value.customized.custom_value_for(custom_field).user_already_rated?
            s << format_easy_rating_value(custom_value)
          else
            sn.times {|i| s << radio_button_tag(field_name + '[rating]', i*(100/(sn-1)), false, :class => 'star {required: true}')}
            custom_value.value = nil
            s << '<div class="easy-rating-desc">' + text_area_tag(field_name + '[description]', '', :id => field_id + '_description', :rows => 4) + '</div>'
          end
          s
        end

        def easy_google_map_address_custom_field_tag(custom_field, custom_value, field_name, field_id, options = {})
          text_area_tag(field_name, custom_value.value, {:id => field_id, :rows => 4, :cols => 50}.merge(options))
        end

        # CUSTOM FIELD TAGS FOR BULK EDIT
        #
        # => "custom field type"_field_tag(custom_field, custom_value, field_name, field_id, projects = nil, value = '', options = {})

        def date_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          (text_field_tag(field_name, value, :id => field_id, :size => 10) + calendar_for(field_id)).html_safe +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        def datetime_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          s = ''
          selected_datetime = nil
          begin
            selected_datetime = value.to_datetime unless value.blank?
          rescue
          end

          s << '<span class="cf-datetime-date">'
          s << text_field_tag(field_name + '[date]', selected_datetime && selected_datetime.to_date, :id => (field_id.to_s + '_date'), :size => 10)
          s << calendar_for((field_id.to_s + '_date'))
          s << '</span><span class="cf-datetime-time">'
          s << select_tag(field_name + '[hour]', options_for_select(24.times.collect{|i| [i+1, i+1]}, :selected => selected_datetime && selected_datetime.hour), :id => (field_id.to_s + '_hour'), :class => 'datetime-custom-field-tag-hour')
          s << l(:label_datetime_custom_field_tag_hour)
          s << select_tag(field_name + '[minute]', options_for_select([['00', '00'], ['15', '15'], ['30', '30'], ['45', '45']], :selected => selected_datetime && selected_datetime.min.to_s), :id => (field_id.to_s + '_minute'), :class => 'datetime-custom-field-tag-minute')
          s << l(:label_datetime_custom_field_tag_minute)
          s.html_safe +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        def text_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          (text_area_tag(field_name, value, :id => field_id, :rows => 3, :style => 'width:90%') + wikitoolbar_for(field_id)).html_safe +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end
        def email_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          email_field_tag(field_name, value, :id => field_id, :rows => 3) +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        def url_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          url_field_tag(field_name, value, :id => field_id, :rows => 3) +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        def bool_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          select_tag(field_name, options_for_select([[l(:label_no_change_option), ''],
                [l(:general_text_yes), '1'],
                [l(:general_text_no), '0']], value), :id => field_id)
        end

        def list_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          options = []
          options << [l(:label_no_change_option), ''] unless custom_field.multiple?
          options << [l(:label_none), '__none__'] unless custom_field.is_required?
          options += custom_field.possible_values_options(projects)
          select_tag(field_name, options_for_select(options, value), :multiple => custom_field.multiple?, :id => field_id)
        end

        def amount_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          text_field_tag(field_name, value, :id => field_id) +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        def easy_lookup_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          selected_values = []
          easy_modal_selector_field_tag(custom_field.settings['entity_type'], custom_field.settings['entity_attribute'], field_name, field_id, selected_values, options) +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        def easy_google_map_address_custom_field_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          text_area_tag(field_name, value, {:id => field_id, :rows => 4, :cols => 50}.merge(options)) +
            get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        # FORMAT CUSTOM FIELD VALUE
        #
        # => format_"custom field type"_value(custom_field_value, options = {})

        def format_datetime_value(custom_value, options = {})
          casted_value = custom_value.cast_value
          t = format_time(casted_value)
          if t
            return t.html_safe
          else
            return ''.html_safe
          end
        end

        def format_easy_lookup_value(custom_value, options = {})
          casted_value = custom_value.cast_value
          casted_value = [casted_value] unless casted_value.is_a?(Array)

          settings = custom_value.custom_field.settings

          entity_class = begin settings['entity_type'].constantize rescue nil end
          if settings['entity_attribute'].start_with?('link_with_')
            attribute = EasyEntityAttribute.new(settings['entity_attribute'].sub('link_with_', ''))
          else
            attribute = EasyEntityAttribute.new(settings['entity_attribute'], {:no_link => true})
          end

          if entity_class && casted_value && !casted_value.blank?
            entities = entity_class.where( :id => casted_value )
            selected_values = casted_value.collect do |id|
              next unless entity = entities.detect{|e| e.id == id.to_i }
              if options[:no_html]
                (format_entity_attribute(entity_class, settings['entity_attribute'], attribute.value(entity), {:entity => entity}) || '').to_str
              else
                (format_html_entity_attribute(entity_class, settings['entity_attribute'], attribute.value(entity), {:entity => entity}) || '').to_str
              end
            end
            selected_values.compact!
          else
            selected_values = nil
          end

          if options[:no_html]
            return selected_values.sort.map{|selected_value| Sanitize.clean(CGI::unescape(selected_value), :output => :html)}.join(', ')  if casted_value && !selected_values.blank?
          else
            selected_values.sort.join(', ').html_safe
          end
        end

        def format_easy_rating_value(custom_value, options = {})
          s = ''
          if custom_value && (custom_field = custom_value.custom_field) && custom_value.value
            if casted_value = custom_value.value.is_a?(Hash) ? custom_value.value['rating'].to_f : custom_value.value.to_f
              s = rating_stars(casted_value, custom_field.star_no, options)
            end
          end
          s.html_safe
        end

        def format_email_value(custom_value, options = {})
          return custom_value.to_s if options[:no_html]
          mail_to(custom_value)
        end

        def format_url_value(custom_value, options = {})
          return custom_value.to_s if options[:no_html]
          link_to(custom_value, custom_value.to_s, :class => 'external', :target => '_blank')
        end

        def format_easy_google_map_address_value(custom_value, options = {})
          return '' if custom_value.nil? || custom_value.value.blank?
          return custom_value.to_s if options[:no_html]
          google_maps_url = "#{Setting.protocol}://maps.google.com/maps?f=q&q=#{custom_value.value.gsub("\n", ',')}&ie=UTF8&om=1"

          s = custom_value.value.to_s.gsub("\n", '<br />')
          s << '<br />'

          s << link_to(l(:button_link_easy_google_map_address), google_maps_url, :class => 'external', :target => '_blank')
          s.html_safe
        end

        def rating_stars(value, star_no = 5, options={})
          if options[:no_html]
            (1 + ((star_no - 1) * (value || 0) / 100)).round.to_s
          else
            s = ''
            s << '<span class="star-rating-control">'
            star_no.times do |i|
              s << "<div class=\"star-rating rater-1 star star-rating-applied star-rating-readonly#{(value/(100.0/(star_no-1))).round >= i ? ' star-rating-on' : ''}\">"
              s << '<a>&nbsp;</a>'
              s << '</div>'
            end
            s << '</span>'
            s.html_safe
          end
        end

        def get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects = nil, value = '', options = {})
          unset_tag = ''
          unless custom_field.is_required?
            unset_tag = content_tag('label',
              check_box_tag(field_name, '__none__', (value == '__none__'), :id => nil, :data => {:disables => "##{field_id}"}) + l(:button_clear),
              :class => 'inline'
            )
          end
          unset_tag.html_safe
        end

      end
    end

    module InstanceMethods

      def custom_fields_tabs_with_easy_extensions
        tabs = custom_fields_tabs_without_easy_extensions
        call_hook(:helper_custom_fields_tabs, :tabs => tabs)
        return tabs
      end

      def custom_field_tag_with_label_with_easy_extensions(name, custom_value, label_tag_options = {}, custom_field_tag_options = {})
        custom_field_label_tag(name, custom_value, label_tag_options) + custom_field_tag(name, custom_value, custom_field_tag_options)
      end

      # Return custom field html tag corresponding to its format
      def custom_field_tag_with_easy_extensions(name, custom_value, options = {})
        custom_field = custom_value.custom_field
        field_name = "#{name}[custom_field_values][#{custom_field.id}]"
        field_name << "[]" if custom_field.multiple?
        field_id = "#{name}_custom_field_values_#{custom_field.id}"
        field_format = Redmine::CustomFieldFormat.find_by_name(custom_field.field_format)

        s = ''
        if !custom_field.internal_name.blank? &&
            (format_field_value_method = "#{custom_field.internal_name.underscore}_custom_field_tag".to_sym) && respond_to?(format_field_value_method)
          s << send(format_field_value_method, custom_field, custom_value, field_name, field_id, options) || ''
        elsif (format_field_value_method = "#{field_format.try(:edit_as).to_s.underscore}_custom_field_tag".to_sym) && respond_to?(format_field_value_method)
          s << send(format_field_value_method, custom_field, custom_value, field_name, field_id, options) || ''
        else
          s << text_field_tag(field_name, custom_value.value, {:id => field_id}.merge(options))
        end

        s.html_safe
      end

      def custom_field_tag_for_bulk_edit_with_easy_extensions(name, custom_field, projects = nil, value='', options = {})
        field_name = "#{name}[custom_field_values][#{custom_field.id}]"
        field_name << "[]" if custom_field.multiple?
        field_id = "#{name}_custom_field_values_#{custom_field.id}"
        field_format = Redmine::CustomFieldFormat.find_by_name(custom_field.field_format)

        format_field_value_method = "#{field_format.try(:edit_as).to_s.underscore}_custom_field_tag_for_bulk_edit".to_sym

        s = ''
        if !custom_field.internal_name.blank? &&
            (format_field_value_method = "#{custom_field.internal_name.underscore}_custom_field_tag_for_bulk_edit".to_sym) && respond_to?(format_field_value_method)
          s << send(format_field_value_method, custom_field, field_name, field_id, projects, value, options) || ''
        elsif (format_field_value_method = "#{field_format.try(:edit_as).to_s.underscore}_custom_field_tag_for_bulk_edit".to_sym) && respond_to?(format_field_value_method)
          s << send(format_field_value_method, custom_field, field_name, field_id, projects, value, options) || ''
        else
          s << text_field_tag(field_name, '', :id => field_id)
          s << get_unset_tag_for_bulk_edit(custom_field, field_name, field_id, projects, value, options)
        end

        s.html_safe
      end

      def show_value_with_easy_extensions(custom_value, options = {})
        return ''.html_safe unless custom_value
        format_custom_field_value(custom_value, options).html_safe
      end

      def custom_field_label_tag_with_easy_extensions(name, custom_field_value, options = {})
        if custom_field_value.custom_field.field_format != 'easy_rating' ||
            !custom_field_value.customized.custom_value_for(custom_field_value.custom_field).user_already_rated? ||
            !custom_field_value.value.blank?

          required = options[:required] || custom_field_value.custom_field.is_required?

          additional_classes = []
          additional_classes << 'required' if required

          content_tag(:label, (custom_field_value.custom_field.translated_name +
                (required ? ' <span class="required">*</span>' : '')).html_safe,
            {:for => "#{name}_custom_field_values_#{custom_field_value.custom_field.id}", :class => additional_classes.join(' ')}.merge(options))
        else
          ''
        end
      end

      def render_api_custom_values_with_easy_extensions(custom_values, api)
        api.array :custom_fields do
          custom_values.each do |custom_value|
            attrs = {:id => custom_value.custom_field_id, :name => custom_value.custom_field.translated_name, :internal_name => custom_value.custom_field.internal_name}
            attrs.merge!(:multiple => true) if custom_value.custom_field.multiple?
            attrs.merge!(:easy_external_id => custom_value.custom_field.easy_external_id) unless custom_value.custom_field.easy_external_id.blank?
            api.custom_field attrs do
              if custom_value.value.is_a?(Array)
                api.array :value do
                  custom_value.value.each do |value|
                    api.value(value) unless value.blank?
                  end
                end
              else
                api.value(custom_value.value)
              end
            end
          end
        end unless custom_values.empty?
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'CustomFieldsHelper', 'EasyPatch::CustomFieldsHelperPatch'
