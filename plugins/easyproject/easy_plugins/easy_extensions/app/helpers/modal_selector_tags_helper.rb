module ModalSelectorTagsHelper
  def self.included(base)

    base.class_eval do

      # Renders modal selector field tag
      #
      # entity_type = 'Issue' or 'Project' or 'User'
      # entity_attribute = 'name' or 'subject' or 'link_with_name'
      # field_name = 'issue[custom_field_values][40]'
      # field_id = 'issue_custom_field_values_40_'
      # selected_values = { 2 => 'Firstname Lastname', 5 => 'Firstname2 Lastname2'}
      #                   or call EasyExtensions::CustomFields::EasyLookupCustomFieldFormat.entity_to_lookup_values(users)
      #                   or call EasyExtensions::CustomFields::EasyLookupCustomFieldFormat.entity_to_lookup_values(issues, :display_name => :subject)
      #                   or call EasyExtensions::CustomFields::EasyLookupCustomFieldFormat.entity_to_lookup_values(issues, :display_name => Proc.new{|issue| link_to_issue(issue)})
      # options:
      #   :url => { :additional_param1 => 'value1', :additional_param2 => 'value2'}
      #   :multiple => '1' or '0'
      def easy_modal_selector_field_tag(entity_type, entity_attribute, field_name, field_id, selected_values = {}, options = {})
        entity_type_underscored = entity_type.underscore
        options[:url] ||= {}
        if options.key?(:multiple)
          options[:url][:multiple] = options.delete(:multiple)
        else
          options[:url][:multiple] = '1'
        end
        if options[:url][:multiple] == '1'
          field_name += '[]' unless field_name =~ /\[\]$/
        end

        main_css = "easy-lookup #{field_id}"
        main_css << ' multiple' if options[:url][:multiple] == '1'
        s = ''
        s << "<span class='#{main_css}' onclick=\"$('##{field_id}_lookup-trigger').click()\">"
        s << "<span id='#{field_id}-no_value' class='display-name' style='display:none;'>" + l(options[:label_none] || :label_none) + '</span>'
        s << "<span id='#{field_id}' class='easy-lookup-values'>"
        if selected_values.blank?
          s << text_field_tag('', '', :disabled => true, :placeholder => l(options[:label_none] || :actionview_instancetag_blank_option), :class => 'display-name placeholder')
        else
          s << (render(:partial => 'modal_selectors/modal_selector_selected_values', :locals => {:selected_values => selected_values, :field_name => field_name, :field_id => field_id, :show_delete_link => false}))
        end
        s << '</span>'
        s << '<span class="easy-lookup-trigger">'

        scr = "$.ajax({url: '#{url_for({:controller => 'modal_selectors', :action => entity_type_underscored, :entity_attribute => entity_attribute, :field_name => field_name, :field_id => field_id}.merge(options[:url]))}',"
          scr << "data: $('.serializable-#{field_id}').closest('form').serialize(),"
          scr << "type: 'post'})"
        scr << ".done(function(data) {
          $('#modal-dialog-loader').html(data);
          showModalSelectorWindow(
            function() {return ['#{url_for({:controller => 'modal_selectors', :action => entity_type_underscored, :entity_attribute => entity_attribute, :field_name => field_name, :field_id => field_id}.merge((options[:url] || {})))}&'+ $('#modal_selector_query_form, .modal-selected-values form').serialize() + '&page=', '']}
            )});"

        s << link_to('', '#', :id => "#{field_id}_lookup-trigger", :title => l("title_easy_modal_selector_trigger.#{entity_type_underscored}"), :class => "icon-add #{entity_type_underscored}")

        s << javascript_tag("$('##{field_id}_lookup-trigger').click(function(e) { " + scr + " return false; });")

        s << '</span>'
        s << '</span>'
        s.html_safe
      end

      # Render link _switching_ _to_ _fullscreen_
      # * element_id - muste exist, its container with content to fullscreen
      # * options - you can change lable & title of buttons and add paramteres to future
      def easy_modal_selector_link_to_fullscreen(element_id, options = {})
        options[:button_fullscreen_label] ||= l(:button_fullscreen)
        options[:button_fullscreen_title] ||= l(:title_fullscreen)
        options[:button_close_label] ||= l(:button_back)
        options[:button_close_title] ||= l(:button_back)

        return link_to_function(options[:button_fullscreen_label], "showFullscreen('#{element_id}','#{options[:button_close_label]}','#{options[:button_close_title]}')", :title => options[:button_fullscreen_title])
      end

      def easy_modal_selector_link_to_fullscreen_by_ajax(url, options = {})

        options[:button_fullscreen_label] ||= l(:button_fullscreen)
        options[:button_fullscreen_title] ||= l(:title_fullscreen)
        options[:complete] ||= 'null'

        link_to_function(options[:button_fullscreen_label], "showAjaxFullscreen('#{url}', #{options[:complete]})",
          :title => options[:button_fullscreen_title],
          :class => options[:class])

      end

      # Renders modal selector link with submit
      #
      # entity_type = 'Issue' or 'Project' or 'User'
      # entity_attribute = 'name' or 'subject' or 'link_with_name'
      # field_name = string - unique field name. This name will be send to :form_url
      # field_id = string - unique field id. This id will be used to data manipulation. Should be same as field_name. (char '[' and ']' will be '_')
      # js_serialize_elements_collection = something like '$(\'issues-form\').getInputs(\'checkbox\', \'ids[]\')'. It is array of all selected elements (checkboxes) from any source list.
      # options:
      #   :form_url => {:controller => '', :action => ''}
      #   :form_options => {:class => 'tabular'}
      #   :url => { :additional_param1 => 'value1', :additional_param2 => 'value2'}}
      #   :trigger_options => {:name => l(:button_send_email), :html => {:title => l(:title_send_email)}}
      def easy_modal_selector_link_with_submit(entity_type, entity_attribute, field_name = '', field_id = '', js_serialize_elements_collection = '[]', options = {})
        options[:trigger_options] ||= {}

        options[:url] ||= {}
        if options.key?(:multiple)
          options[:url][:multiple] = options.delete(:multiple)
        else
          options[:url][:multiple] = '1'
        end
        if options[:url][:multiple] == '1'
          field_name += '[]' unless field_name =~ /\[\]$/
        end

        entity_type_underscored = entity_type.underscore
        s = ''
        s << form_tag((options[:form_url] || {}), {:id => (field_id + '-form'), :style => 'display:none'}.merge((options[:form_options] || {})))
        s << "<div id='#{field_id}-form-hook-hiddens'></div>"
        s << "<div id='#{field_id}-form-hiddens'></div>"
        s << '</form>'
        s << javascript_tag("function beforeCloseModalSelectorWindow_#{field_id}(){$('#ajax-indicator').show();
          copySelectedModalEntities('#{field_id}-modal-selected-values-container', '#{field_id}-form-hiddens');
          if ($('##{field_id}-form')[0].action.indexOf('?') >= 0)
            {
              $('##{field_id}-form')[0].action= $('##{field_id}-form')[0].action + '&' + $('##{field_id}-modal-hook-form').serialize();
            }
          else
            {
              $('##{field_id}-form')[0].action= $('##{field_id}-form')[0].action + '?' + $('##{field_id}-modal-hook-form').serialize();
            }

            $('##{field_id}-form').submit();}")
        url = url_for({:controller => 'modal_selectors', :action => entity_type_underscored, :entity_attribute => entity_attribute, :field_name => field_name, :field_id => field_id}.merge((options[:url] || {})))
        fce = "$.post('#{j(url)}'"
          fce << ", $(#{js_serialize_elements_collection}).serialize(), "
           fce << "function(data) {
           $('#modal-dialog-loader').html(data);

           if ($('#selected_columns')[0]) {
              selectAllOptions('selected_columns')
            };
            showModalSelectorWindow(
              function() {
                return ['#{j(url)}&'+ $('#modal-dialog-loader form').serialize() + '&page=', ''];
              }
            )}"

          fce << ");"

          s << link_to_function((options[:trigger_options][:name] || ''), fce.html_safe, (options[:trigger_options][:html] || {}))

          s.html_safe
          end

          def render_modal_selector_easy_query_list(query, entities, entity_pages, entity_count, selected_values, options, &entity_link_block)
            render(:partial => 'modal_selectors/modal_selector_easy_query_list', :locals => {:query => query, :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :options => options, :entity_link_block => entity_link_block})
          end

          def render_modal_selector_easy_query_tree(query, entities, entity_pages, entity_count, selected_values, options, &entity_link_block)
            render(:partial => 'modal_selectors/modal_selector_easy_query_tree', :locals => {:query => query, :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :options => options, :entity_link_block => entity_link_block})
          end

          def render_modal_selector_easy_query_multi_tree(query, entities, entity_pages, entity_count, selected_values, options, &entity_link_block)
            render(:partial => 'modal_selectors/modal_selector_easy_query_multi_tree', :locals => {:query => query, :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :options => options, :entity_link_block => entity_link_block})
          end

          end
     end
end