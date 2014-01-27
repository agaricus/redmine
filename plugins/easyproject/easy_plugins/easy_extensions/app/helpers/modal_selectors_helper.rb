# For using only in ModalSelectorsController
module ModalSelectorsHelper

  def self.included(base)
    base.send(:include, InstanceMethods) if base.include?(SortHelper)

    base.class_eval do

      alias_method_chain(:sort_link, :easy_extensions) if base.include?(SortHelper)

      #options
      # => :field_name = string if field_name should be different in this case
      def entity_modal_selector_checker(entity, selected_values, multiple = '1', options={})
        # TMP PATCH (maybe forever)

        if params['entity_attribute'].start_with?('link_with_')
          attribute = EasyEntityAttribute.new(params['entity_attribute'].sub('link_with_', ''))
        else
          attribute = EasyEntityAttribute.new(params['entity_attribute'], {:no_link => true})
        end

        field_name = options[:field_name] || params['field_name']
        if multiple == '1'
          entity_modal_selector_check_box(entity, attribute, selected_values, field_name)
        else
          entity_modal_selector_radio_button(entity, attribute, selected_values, field_name)
        end
      end

      def entity_modal_selector_check_box(entity, attribute, selected_values, field_name)
        s = check_box_tag("ids[]", entity.id, selected_values && selected_values.detect{|a,b| a == entity.id.to_s}, :id => "cbx-#{entity.id}", :onchange => "changeModalSelectorValue('#{params['field_id']}', 'cbx-#{entity.id}', 'display-value-#{entity.id}', 'display-value-escaped-#{entity.id}', '#{field_name}', '#{params['field_id']}', true);")
        s << hidden_field_tag("display_value[#{entity.id}]", (format_html_entity_attribute(entity.class, params['entity_attribute'], attribute.value(entity), {:entity => entity}) || '').to_str, :id => "display-value-#{entity.id}")
        s << hidden_field_tag("display_value_escaped[#{entity.id}]", CGI::escape(format_html_entity_attribute(entity.class, params['entity_attribute'], attribute.value(entity), {:entity => entity}).to_str), :id => "display-value-escaped-#{entity.id}")
        s.html_safe
      end

      def entity_modal_selector_radio_button(entity, attribute, selected_values, field_name)
        s = radio_button_tag("ids[]", entity.id, selected_values && selected_values.detect{|a,b| a == entity.id.to_s}, :id => "cbx-#{entity.id}", :onchange => "changeModalSelectorValue('#{params['field_id']}', 'cbx-#{entity.id}', 'display-value-#{entity.id}', 'display-value-escaped-#{entity.id}', '#{field_name}', '#{params['field_id']}', false);")
        s << hidden_field_tag("display_value[#{entity.id}]", (format_html_entity_attribute(entity.class, params['entity_attribute'], attribute.value(entity), {:entity => entity}) || '').to_str, :id => "display-value-#{entity.id}")
        s << hidden_field_tag("display_value_escaped[#{entity.id}]", CGI::escape(format_html_entity_attribute(entity.class, params['entity_attribute'], attribute.value(entity), {:entity => entity}).to_str), :id => "display-value-escaped-#{entity.id}")
        s.html_safe
      end

      #disables original links
      def per_page_links(selected=nil, item_count=nil)
      end

      private
#
#      def link_to_content_update(text, url_params = {}, html_options = {})
#        link_to_function(text, "selectAllOptions('selected_columns');$.ajax({url: '#{j(url_for(url_params))}', type: 'post', data: $('#modal-dialog-loader form').serialize()}).done(function(data) {$('#modal-dialog-loader').html(data)})",
#          html_options
#        )
#      end


    end
  end

  module InstanceMethods

    def sort_link_with_easy_extensions(column, caption, default_order)
      css, order = nil, default_order
      if column.to_s == @sort_criteria.first_key
        if @sort_criteria.first_asc?
          css = 'sort asc'
          order = 'desc'
        else
          css = 'sort desc'
          order = 'asc'
        end
      end
      caption = column.to_s.humanize unless caption

      sort_options = { :sort => @sort_criteria.add(column.to_s, order).to_param }
      # don't reuse params if filters are present
      url_options = params.has_key?(:set_filter) ? sort_options : params.merge(sort_options)

      # Add project_id to url_options
      url_options = url_options.merge(:project_id => params[:project_id]) if params.has_key?(:project_id)

      link_to_function(caption, "selectAllOptions('selected_columns');$.ajax({url: '#{j(url_for(url_options))}', type: 'post', data: $('#modal-dialog-loader form').serialize()}).done(function(data) {bindInfiniteScrollModalSelector(); $('#modal-dialog-loader').html(data)})",
        {:class => css})
    end
  end

end
