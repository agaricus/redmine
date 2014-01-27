# encoding: utf-8
module EasyPatch
  module ApplicationHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :checked_image, :easy_extensions
        alias_method_chain :authorize_for, :easy_extensions
        alias_method_chain :avatar, :easy_extensions
        alias_method_chain :breadcrumb, :easy_extensions
        alias_method_chain :body_css_classes, :easy_extensions
        alias_method_chain :context_menu, :easy_extensions
        alias_method_chain :current_theme, :easy_extensions
        alias_method_chain :format_activity_description, :easy_extensions
        alias_method_chain :html_title, :easy_extensions
        alias_method_chain :include_calendar_headers_tags, :easy_extensions
        alias_method_chain :link_to_attachment, :easy_extensions
        alias_method_chain :link_to_issue, :easy_extensions
        alias_method_chain :link_to_project, :easy_extensions
        alias_method_chain :link_to_user, :easy_extensions
        alias_method_chain :other_formats_links, :easy_extensions
        alias_method_chain :preview_link, :easy_extensions
        alias_method_chain :principals_check_box_tags, :easy_extensions
        alias_method_chain :progress_bar, :easy_extensions
        alias_method_chain :project_tree_options_for_select, :easy_extensions
        alias_method_chain :render_flash_messages, :easy_extensions
        alias_method_chain :render_project_jump_box, :easy_extensions
        alias_method_chain :render_tabs, :easy_extensions
        alias_method_chain :sidebar_content?, :easy_extensions
        alias_method_chain :stylesheet_link_tag, :easy_extensions
        alias_method_chain :thumbnail_tag, :easy_extensions
        alias_method_chain :toggle_link, :easy_extensions

        def link_to_remote(name, options = {}, html_options = nil)
          ActiveSupport::Deprecation.warn('link_to_remote is deprecated! user link_to :remote => true !!!')
          link_to_function(name, remote_function(options), html_options || options.delete(:html))
        end

        def remote_function(options)
          ActiveSupport::Deprecation.warn('remote_function is deprecated!!!!')
          javascript_options = options_for_ajax(options)

          #          update = ''
          #          if options[:update] && options[:update].is_a?(Hash)
          #            update  = []
          #            update << "success:'#{options[:update][:success]}'" if options[:update][:success]
          #            update << "failure:'#{options[:update][:failure]}'" if options[:update][:failure]
          #            update  = '{' + update.join(',') + '}'
          #          elsif options[:update]
          #            update << "'#{options[:update]}'"
          #          end
          #
          #          function = update.empty? ?
          #            "new Ajax.Request(" :
          #            "new Ajax.Updater(#{update}, "

          function = "$.ajax({url:"

          url_options = options[:url]
          function << "'#{html_escape(j(url_for(url_options)))}'"
          function << ", #{javascript_options}" if javascript_options.present?
          function << '})'
          function << ".done(function() {#{options[:complete]}})" if options[:complete]
          function << ".always(function(data) {$('##{options[:update]}').html(data)})" if options[:update].is_a? String

          function = "#{options[:before]}; #{function}" if options[:before]
          function = "#{function}; #{options[:after]}"  if options[:after]
          function = "if (#{options[:condition]}) { #{function}; }" if options[:condition]
          function = "if (confirm('#{j(options[:confirm])}')) { #{function}; }" if options[:confirm]

          return function.html_safe
        end

        def options_for_ajax(options)
          js_options = {}

          js_options['async'] = options[:type] != :synchronous
          js_options['type']       = options[:method].to_s if options[:method]

          ActiveSupport::Deprecation.warn('options_for_ajax: options[:position] is deprecated!') if options[:position]
          ActiveSupport::Deprecation.warn('options_for_ajax: options[:script] is deprecated!') if options[:script]
          #          js_options['insertion']    = "'#{options[:position].to_s.downcase}'" if options[:position]
          #          js_options['evalScripts']  = options[:script].nil? || options[:script]

          if options[:form]
            js_options['data'] = 'this.form.serialize()'
          elsif options[:submit]
            js_options['data'] = "$('##{options[:submit]}).serialize()'"
          elsif options[:with]
            js_options['data'] = options[:with]
          end

          #          if protect_against_forgery? && !options[:form]
          #            if js_options['parameters']
          #              js_options['parameters'] << " + '&"
          #            else
          #              js_options['parameters'] = "'"
          #            end
          #            js_options['parameters'] << "#{request_forgery_protection_token}=' + encodeURIComponent('#{j form_authenticity_token}')"
          #          end

          return "#{js_options.keys.map { |k| "#{k}:#{js_options[k]}" }.sort.join(', ')}"
        end

        def easy_stylesheet_link_tag(*sources)
          @easy_stylesheet_link_tags ||= Hash.new { |hash, key| hash[key] = Array.new }
          # :default => 'plugin_assets/easy_default_cache_css'
          # @easy_stylesheet_link_tags ||= Hash.new { |hash, key| hash[key] = Hash.new }
          options = sources.extract_options!

          if sources.empty?
            links = ''
            # @easy_stylesheet_link_tags.sort_by{|k,v| v[:position]}.each do |k,v|
            #   next if v[:files].empty?
            #   links << stylesheet_link_tag(*(v[:files].compact+[{:cache => k, :media => 'all'}]))
            # end
            @easy_stylesheet_link_tags.each do |plugin, h_sources|
              h_sources.each do |source|
                links << stylesheet_link_tag(source, {:plugin => plugin})
              end
            end

            return links.html_safe
          else
            # plugin = options.delete(:plugin)
            # use_cache = options.delete(:cache_file) || "easy_default_cached_css#{current_theme && current_theme.dir}"
            # use_cache_in = options.delete(:cache_path) || 'plugin_assets/easy_extensions/stylesheets'

            # cache_key = options.delete(:cache_key) || File.join('/', use_cache_in, use_cache)

            # @easy_stylesheet_link_tags[cache_key][:files] ||= Array.new
            # @easy_stylesheet_link_tags[cache_key][:position] = options[:position] if options[:position]
            # @easy_stylesheet_link_tags[cache_key][:position] ||= @easy_stylesheet_link_tags.keys.size

            sources.each do |source|
              @easy_stylesheet_link_tags[options[:plugin]] << source
              # if plugin
              #   css_source = "/plugin_assets/#{plugin}/stylesheets/#{source}"
              # else
              #   css_source = source
              # end

              # unless @easy_stylesheet_link_tags[cache_key][:files].include?(css_source)

              #   if options[:position_file_at] && @easy_stylesheet_link_tags[cache_key][:files].count >= options[:position_file_at]
              #     @easy_stylesheet_link_tags[cache_key][:files].insert(options[:position_file_at], css_source)
              #   else
              #     @easy_stylesheet_link_tags[cache_key][:files] << css_source
              #   end
              # end
            end

          end
        end

        def easy_javascript_include_tag(*sources)
          @easy_javascript_include_tags ||= ActiveSupport::OrderedHash.new { |hash, key| hash[key] = Array.new }
          # @easy_javascript_include_tags ||= []
          options = sources.extract_options!

          if sources.empty?
            scripts = ''
            @easy_javascript_include_tags.each do |plugin, j_sources|
              j_sources.each do |source|
                scripts << javascript_include_tag(source, {:plugin => plugin})
              end
            end
            #javascript_include_tag(*(@easy_javascript_include_tags + [{:cache => '/plugin_assets/easy_extensions/javascripts/js_all'}]))
            return scripts.html_safe
          else
            plugin = options.delete(:plugin)

            sources.each do |source|
              # if plugin
              #   js_source=  "/plugin_assets/#{plugin}/javascripts/#{source}"
              # else
              #   js_source = source
              # end
              #@easy_javascript_include_tags << js_source unless @easy_javascript_include_tags.include?(js_source)
              @easy_javascript_include_tags[plugin] << source
            end

          end
        end

        def easy_theme_tag(source, options = {})
          theme_tags = Array.new
          if current_theme
            if current_theme.stylesheets.include?(source)
              if current_theme.is_easy_theme? && @easy_theme_styles_included.nil?
                css_links = []

                css_links << 'basic'
                css_links << 'application_core'
                css_links << 'menu'
                css_links << 'easy_design'
                css_links << 'easy_icons'

                unless in_mobile_view?
                  theme_tags << stylesheet_link_tag('main_ep_layout', :plugin => 'easy_extensions') if current_theme == Redmine::Themes.theme('easy')
                end

                theme_tags << stylesheet_link_tag(*(css_links + [{:media => 'all', :plugin => 'easy_extensions'}]))

                theme_tags << stylesheet_link_tag('easy_gradients')

                theme_tags << stylesheet_link_tag('easy_print', :media => (options[:media] || 'print'), :plugin => 'easy_extensions')

                @easy_theme_styles_included = true
              end
              theme_tags << stylesheet_link_tag(source, :media => options[:media])
            end
          else
            if @redmine_application_css.nil?
              theme_tags << stylesheet_link_tag('application', :media => 'all')
              @redmine_application_css = true
            end
          end

          # if current_theme && current_theme.javascripts.include?(source)
          #   easy_javascript_include_tag(current_theme.javascript_path(source) + '.js')
          # end

          return theme_tags.join('').html_safe
        end

        def hh(text)
          text.is_a?(Symbol) ? l(text) : h(text)
        end

        def hour_to_string(hour)
          hour > 9 ? hour.to_s.html_safe : ('0' + hour.to_s).html_safe
        end

        def min_to_string(min)
          min > 9 ? (min.to_s.html_safe) : ('0' + min.to_s).html_safe
        end

        # Cheap knock off of the tabular form builder's labeling
        def label_for_field(field, options = {})
          return '' if options.delete(:no_label)
          text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
          text ||= l(('field_' + field.to_s.gsub(/\_id$/, '')).to_sym)

          additional_classes = []
          additional_classes << 'error' if @object && @object.errors[field]

          if options.delete(:required)
            text += content_tag(:span, ' *', :class => "required")
            additional_classes << 'required'
          end

          additional_for = '_'
          if options.key?(:additional_for)
            additional_for += options.delete(:additional_for).to_s + '_'
          end

          content_tag(:label, text.html_safe,
            :class => additional_classes.join(' '),
            :for => (@object_name.to_s + additional_for + field.to_s)).html_safe
        end

        def datetime_tag(time, options={})
          text = format_time(time)
          if @project
            link_to(h(text), {:controller => 'activities', :action => 'index', :id => @project, :from => time.to_date, :only_path => (options[:only_path].nil? ? true : options[:only_path])}, :title => format_time(time)).html_safe
          else
            content_tag('acronym', text, :title => format_time(time)).html_safe
          end
        end

        def project_tree_select(projects, options={})
          return ''.html_safe if projects.empty?

          for_select, for_options = options.dup, options.dup
          for_select.delete(:include_blank)
          for_select.delete(:prompt)
          for_options.delete(:data)

          select_tag(for_select[:name], project_tree_options_for_select(projects, for_options).html_safe, for_select)
        end

        def remote_reorder_links(name, url, options={})
          (
            link_to(image_tag('2uparrow.png'  , :alt => l(:label_sort_highest)), url.merge("#{name}[move_to]" => 'highest'), {:title => l(:label_sort_highest), :remote => true}.merge(options)) +
              link_to(image_tag('1uparrow.png'  , :alt => l(:label_sort_higher )), url.merge("#{name}[move_to]" => 'higher' ), {:title => l(:label_sort_higher ), :remote => true}.merge(options)) +
              link_to(image_tag('1downarrow.png', :alt => l(:label_sort_lower  )), url.merge("#{name}[move_to]" => 'lower'  ), {:title => l(:label_sort_lower  ), :remote => true}.merge(options)) +
              link_to(image_tag('2downarrow.png', :alt => l(:label_sort_lowest )), url.merge("#{name}[move_to]" => 'lowest' ), {:title => l(:label_sort_lowest ), :remote => true}.merge(options))
          ).html_safe
        end

        def entity_tree_options_for_select(entities, options = {})
          s = ''
          entities.sort_by(&:lft).each do |entity|
            name_prefix = (entity.level > 0 ? ('&nbsp;' * 2 * entity.level + '&#187; ') : '')
            selected_value = entity

            if (options[:selected].is_a?(Array) && options[:selected].size > 0)
              first_item = options[:selected].first
              selected_value = (first_item.is_a?(String) ? entity.id.to_s : entity.id) if first_item.class != entity.class
            elsif (!options[:selected].blank? && !options[:selected].is_a?(Array))
              if (options[:selected].is_a?(String))
                if (options[:selected].to_i == entity.id)
                  selected_value = options[:selected]
                end
              else
                if (options[:selected].id == entity.id)
                  selected_value = options[:selected]
                end
              end
            end

            tag_options = {:value => entity.id, :selected => (option_value_selected?(selected_value, options[:selected]) ? 'selected' : nil)}
            tag_options.merge!(yield(entity)) if block_given?
            s << content_tag('option', name_prefix + h(entity.to_s), tag_options)
          end
          s.html_safe
        end

        def show_shorter_value(value, options={})
          val = value.to_s.utf8_safe_split(options[:size])[0].to_s
          if (val == value.to_s)
            val.html_safe
          else
            (val + (options.has_key?(:appendix) ? options[:appendix] : '')).html_safe
          end
        end

        #        def show_profit(revenues, expenses)
        #          done = 0
        #          if (revenues == 0.0)
        #            done = 0
        #          else
        #            done = ((expenses / revenues) * 100).round
        #          end
        #
        #          if (revenues < expenses)
        #            done = done - 100
        #          end
        #          show_number(done, "#{done} %")
        #        end

        def format_price(price, currency = nil)
          currency ||= l('number.currency.format.unit', :locale => :cs)

          format_number(price, number_to_currency(price, :precision => 0, :unit => currency, :delimiter => ' ', :format => "%n %u"))
        end

        def format_number(number, value = nil)
          value ||= number.to_s
          s = '<span'
          s << ' class="overdrawn"' if (number || 0) < 0
          s << '>'
          s << value.to_s
          s << '</span>'
          s.html_safe
        end

        def format_hours(value, options = {})
          value = value.to_f
          format = options[:format] || '%.2f'
          if options[:unit]
            format_number(value, html_hours("#{format} #{options[:unit]}" % value)).html_safe
          else
            l((value < 2.0 ? :label_f_hour : :label_f_hour_plural), :value => format_number(value, html_hours("#{format}" % value))).html_safe
          end
        end

        def format_time_range( start_time, end_time, include_date = false)
          return '' unless start_time && end_time
          format_time( start_time, include_date ) + ' - ' + format_time( end_time, include_date )
        end

        def hourstimecheck_collection_for_select_options(selected, options={})
          collection = []
          collection << options[:first_option] if options[:first_option]

          24.times do |hour|
            4.times do |minute|
              value = hour_to_string(hour) + ':' + min_to_string(minute * 15)
              collection << [value, value]
            end
          end

          if options[:include_24]
            value = hour_to_string(24) + ':' + min_to_string(0)
            collection << [value, value]
          end

          options_for_select(collection, selected)
        end

        # status_bar([predicted_costs, sum_of_costs])
        def status_bar(pcts, options={})
          done = 0
          if (pcts[0] == 0.0)
            done = ((pcts[1] == 0.0) ? 0 : -100)
          else
            done = ((pcts[1] / pcts[0]) * 100).round
          end

          options[:legend] = done.to_s + '%' unless options[:legend]
          options[:progress_class] = "overdrawn" if done < 0

          if (pcts[0] < pcts[1])
            done = done - 100
          end

          done = 100 if (done < 0)

          progress_bar(done, options)
        end

        def project_plus_button(has_children, element_id, uniq_prefix,user=nil)
          user ||= User.current
          html = ""
          html << '<span '
          html << 'class="expander" ' if has_children
          html << "onclick=\"javascript:ToggleTableRowVisibility('#{uniq_prefix}', 'project', '#{element_id}', '#{user.id}', true);\" alt='Expander' title='#{l(:collapse_expand)}'>&nbsp;</span>"
          html.html_safe
        end

        def project_descendant_plus_button(project_id, uniq_prefix, open=false)
          "<span class=\"expander descendant-expander #{'open' if open}\" data-id=\"#{project_id}\" data-prefix=\"#{uniq_prefix}\">&nbsp;</span>".html_safe
        end

        def project_root_plus_button(root_id, open=false)
          "<span class=\"expander root-expander #{'open' if open}\" data-id=\"#{root_id}\">&nbsp;</span>".html_safe
        end

        def filter_plus_button(is_group_blank,colspan,uniq_id,content,count,user = nil)
          user ||= User.current
          html = ""
          html << "<tr class='group #{'open' if toggle_button_expanded?(uniq_id, user, true)}' id='#{uniq_id }'>"
          html << "<td colspan='#{colspan}' class='inline_expander'>"
          html << "<span class='expander' onclick=\"issuesToggleRowGroup('#{uniq_id}','#{user.id}'); return false;\" alt='Expander' title='#{l(:collapse_expand)}'>&nbsp;</span>"
          if is_group_blank
            html << "#{t(:label_none)}"
          else
            html << content if content
          end
          html << "<span class='count'>(#{count})</span></td></tr>" unless count.blank?
          html.html_safe
        end

        # options:
        # => options[:heading] = text beside of plus button
        # => options[:container_html] = a hash of html attributes
        # => options[:default_button_state] = (true => expanded -), (false => collapsed +)
        # => options[:ajax_call] = make ajax call for saving state (true => ajax call, false => no call, no save)
        # => options[:wrapping_heading_element] = html element outside heading => h3, h4
        def toggling_container(container_uniq_id, user = nil, options={}, &block)
          container_uniq_id = container_uniq_id.dup << '_mobile' if is_mobile_device?
          user ||= User.current
          options[:heading] ||= ''
          options[:heading_links] ||= []
          options[:heading_links] = [options[:heading_links]] unless options[:heading_links].is_a?(Array)
          options[:container_html] ||= {}
          options[:default_button_state] = false if is_mobile_device?
          options[:default_button_state] = true if options[:default_button_state].nil?
          options[:ajax_call] = true if options[:ajax_call].nil?

          unless options.key?(:no_heading_button)
            options[:heading] += content_tag(:div, options[:heading_links].join.html_safe, :class => 'module-heading-links') unless options[:heading_links].blank?
            concat(module_minus_button(user, options[:heading].html_safe, container_uniq_id, {:default => options[:default_button_state], :wrapping_heading_element => options[:wrapping_heading_element], :expander_options => options[:expander_options], :ajax_call => options[:ajax_call]}))
          end

          (content_tag(:div, {
                :id => container_uniq_id,
                :style => (toggle_button_expanded?(container_uniq_id, user, options[:default_button_state]) ? '' : 'display:none')
              }.merge(options[:container_html]){|k, o, n| "#{o}; #{n}"}, &block))
        end

        def toggling_container_string(container_uniq_id, user = nil, options={}, &block)
          user ||= User.current
          options[:heading] ||= ''
          options[:heading_links] ||= []
          options[:heading_links] = [options[:heading_links]] unless options[:heading_links].is_a?(Array)
          options[:container_html] ||= {}
          options[:default_button_state] = true if options[:default_button_state].nil?
          options[:ajax_call] = true if options[:ajax_call].nil?

          output_html = ''

          unless options.key?(:no_heading_button)
            options[:heading] += content_tag(:div, options[:heading_links].join.html_safe, :class => 'module-heading-links') unless options[:heading_links].blank?
            output_html << module_minus_button(user, options[:heading], container_uniq_id, {:default => options[:default_button_state], :wrapping_heading_element => options[:wrapping_heading_element], :expander_options => options[:expander_options], :ajax_call => options[:ajax_call]})
          end

          output_html << content_tag(:div, block.call.to_s.html_safe, {
              :id => container_uniq_id,
              :style => (toggle_button_expanded?(container_uniq_id, user, options[:default_button_state]) ? '' : 'display:none')
            }.merge(options[:container_html]))

          output_html.html_safe
        end

        def module_minus_button(user, content, modul_uniq_id, options={})
          if options[:default].nil?
            default = true
          else
            default = options[:default]
          end
          expander_options = options[:expander_options] || {}
          wrapping_heading_element = options[:wrapping_heading_element] || 'h3'
          ajax_call = options.delete(:ajax_call) ? 'true' : 'false'

          html = ''
          html << '<div class="module-toggle-button">'
          html << "<div class='group #{'open' if toggle_button_expanded?(modul_uniq_id, user, default)}' >"
          html << "<span class='expander #{expander_options[:class]}' onclick=\"toggleMyPageModule($(this),'#{modul_uniq_id}','#{user.id}', #{ajax_call}); return false;\">&nbsp;</span>"
          html << content_tag(wrapping_heading_element, content, :class => 'module-heading', :onclick => "toggleMyPageModule(this,'#{modul_uniq_id}','#{user.id}', #{ajax_call})")
          html << '</div></div>'
          html.html_safe
        end

        # If default = true, then minus(-) is visible, because content is expanded. If default = false then plus(+) is visible, because content is collapsed.
        def toggle_button_expanded?(uniq_id, user = nil, default = true)
          user ||= User.current
          if user.preference && user.preference[:plus_button_status] && user.preference[:plus_button_status].key?(uniq_id)
            show_minus = !user.preference[:plus_button_status][uniq_id]
          end
          show_minus = default if show_minus.nil?
          show_minus
        end

        def toggle_open_css_row(uniq_id, user = nil, default = false)
          toggle_button_expanded?(uniq_id, user, default) ? ' open'.html_safe : ''.html_safe
        end

        def toggle_display_style_row(basic_id, entity = nil, user = nil, entity_name = nil, default = false)
          ret = false
          if entity
            if parent = entity.parent
              parent_prefix = basic_id + (entity_name.nil? ? entity.class.name.underscore : entity_name) + '-' + parent.id.to_s
              ret ||= !toggle_button_expanded?(parent_prefix, user, default)
            end
            if root = entity.root
              root_prefix = basic_id + (entity_name.nil? ? entity.class.name.underscore : entity_name) + '-' + root.id.to_s
              ret ||= !toggle_button_expanded?(root_prefix, user, default)
            end
          else
            ret ||= !toggle_button_expanded?(basic_id, user, default)
          end

          if ret
            'style="display:none"'.html_safe
          else
            ''.html_safe
          end
        end

        def filter_show_project(f_uniq_id)
          return if f_uniq_id.nil?
          return 'was-hidden'.html_safe if toggle_button_expanded?(f_uniq_id)
        end

        # hide elements for issues and users
        def detect_hide_elements(uniq_id, user = nil, default = true)
          return ''.html_safe if uniq_id.blank?
          return 'style="display:none"'.html_safe if !toggle_button_expanded?(uniq_id, user, default)
        end

        # return options for date and datetime select in easy_query
        def options_for_period_select(value, field=nil, options={})
          no_category = [
            [l(:label_all_time), 'all']
          ]
          past_items = [
            [l(:label_yesterday), 'yesterday'],
            [l(:label_last_week), 'last_week'],
            [l(:label_last_n_weeks, 2), 'last_2_weeks'],
            [l(:label_last_n_days, 7), '7_days'],
            [l(:label_last_month), 'last_month'],
            [l(:label_last_n_days, 30), '30_days'],
            [l(:label_last_n_days, 90), '90_days'],
            [l(:label_last_year), 'last_year']
          ]
          present_items = [
            [l(:label_today), 'today'],
            [l(:label_this_week), 'current_week'],
            [l(:label_this_month), 'current_month'],
            [l(:label_this_year), 'current_year'],
            [l(:label_last_n_days_next_m_days, :last => 30, :next => 90), 'last30_next90']
          ]
          if options[:disabled_values].is_a? Array
            no_category.delete_if{|item| options[:disabled_values].include?(item[1])}
            past_items.delete_if{|item| options[:disabled_values].include?(item[1])}
            present_items.delete_if{|item| options[:disabled_values].include?(item[1])}
          end

          future_items = Array.new
          if field
            no_category << [l(:label_is_null), 'is_null'] if eqeoc(:is_null, field, options)
            no_category << [l(:label_is_not_null), 'is_not_null'] if eqeoc(:is_not_null, field, options)
            present_items << [l(:label_to_today), 'to_today'] if eqeoc(:to_today, field, options)
            # future stuff
            future_items << [l(:label_tomorrow), 'tomorrow'] if eqeoc( :tomorrow, field, options)
            future_items << [l(:label_next_week), 'next_week'] if eqeoc( :next_week, field, options)
            future_items << [l(:label_next_n_days, :days => 5), 'next_5_days'] if eqeoc( :next_5_days, field, options)
            future_items << [l(:label_next_n_days, :days => 7), 'next_7_days'] if eqeoc( :next_7_days, field, options)
            future_items << [l(:label_next_n_days, :days => 10), 'next_10_days'] if eqeoc( :next_10_days, field, options)
            future_items << [l(:label_next_month), 'next_month'] if eqeoc( :next_month, field, options)
            future_items << [l(:label_next_n_days, :days => 30), 'next_30_days'] if eqeoc( :next_30_days, field, options)
            future_items << [l(:label_next_n_days, :days => 90), 'next_90_days'] if eqeoc( :next_90_days, field, options)
            future_items << [l(:label_next_year), 'next_year'] if eqeoc( :next_year, field, options)
            # extended stuff
            future_items << [l(:label_after_due_date), 'after_due_date'] if eqeoc( :after_due_date, field, options)
          end
          call_hook(:application_helper_options_for_period_select_bottom, {:past_items => past_items, :present_items => present_items, :future_items => future_items, :field => field, :options => options})
          r = Array.new
          r << [nil, no_category]
          r << [l(:label_period_past), past_items]
          r << [l(:label_period_present), present_items]
          r << [l(:label_period_future), future_items] if future_items.any?

          return grouped_options_for_select(r, value)
        end

        def easy_page_context
          if is_a?(ApplicationController)
            @__easy_page_ctx
          else
            controller.easy_page_context
          end
        end

        def prepare_easy_page_for_render
          if (tabs = easy_page_context[:page_params][:tabs]) && tabs.count > 1 && current_tab = easy_page_context[:page_params][:current_tab]
            html_title(current_tab.name)
          end

          has_any_module = easy_page_context[:page_modules].inject(false){|sum, obj| sum || !obj[1].blank?}
          tab_pos = (current_tab && current_tab.position) || 1

          easy_page_context[:page_modules].keys.each_with_index do |zone_name, idx|
            content_for(('easy_page_zone_' + zone_name.underscore).to_sym) do
              s = "<div id=\"tab#{tab_pos}-list-#{zone_name.dasherize}\" class=\"easy-page-zone\">"

              if has_any_module
                easy_page_context[:page_modules][zone_name].each do |page_module|
                  if page_module.module_definition.module_allowed?
                    if easy_page_context[:page_params][:edit]
                      s << render(:partial => 'easy_page_layout/page_module_edit_container', :locals => {:page_params => easy_page_context[:page_params], :page_module => page_module})
                    else
                      s << render(:partial => 'easy_page_layout/page_module_show_container', :locals => {:page_params => easy_page_context[:page_params], :page_module => page_module})
                    end
                  end
                end
              elsif idx == 0 && !easy_page_context[:page_params][:edit]
                s << render(:partial => 'easy_page_modules/empty_zone', :locals => {})
              end

              s << '</div>'
              s.html_safe
            end
          end
        end

        def render_easy_page_editable_tabs
          return unless easy_page_context
          tabs = easy_page_context[:page_params][:tabs]

          if tabs
            current_tab = easy_page_context[:page_params][:current_tab]
            render(:partial => 'common/easy_page_editable_tabs', :locals => {:tabs => tabs, :editable => easy_page_context[:page_params][:edit], :selected_tab => (current_tab && current_tab.position)}) if tabs.size > 0
          end
        end

        def link_to_entity(entity, options={}, html_options = nil)
          case entity.class.name
          when 'Attachment'
            link_to_attachment(entity, options)
          when 'Document'
            link_to_document(entity, options)
          when 'Issue'
            options[:html] ||= {}
            options[:html].merge!(html_options || {})
            link_to_issue(entity, options)
          when 'Journal'
            link_to_journal(entity, options)
          when 'Project'
            link_to_project(entity, options, html_options || {})
          when 'User'
            link_to_user(entity, options)
          else
            link_to('Link is missing', {})
          end
        end

        def link_to_journal(journal, options={})
          title = nil
          subject = nil
          if options[:subject] == false
            title = truncate(journal.issue.subject, :length => 60)
          else
            subject = journal.issue.subject
            if options[:truncate]
              subject = truncate(subject, :length => options[:truncate])
            end
          end
          s = link_to("#{journal.issue.tracker}", url_to_journal(journal),
            {:class => journal.issue.css_classes,
              :title => title}.merge(options[:html] || {}))
          s << ": #{h subject}" if subject
          s = "#{h journal.issue.project} - " + s if options[:project]
          s.html_safe
        end

        def link_to_document(document, options={})
          link_to(h(document.title), url_to_document(document))
        end

        def render_menu_more(menu=nil, project=nil, options={}, &block)
          if block.nil?
            links = []
            menu_items_for(menu, project) do |node|
              links << render_menu_node(node, project)
            end
            return ''.html_safe if links.empty?
            html_links = links.join("\n")
          else
            html_links = with_output_buffer(&block)
          end
          return ''.html_safe if html_links.blank?
          return content_tag(:div, html_links.html_safe, :class => 'easy-redmine-menu-more') if !in_mobile_view? && current_theme && !current_theme.is_easy_theme?
          return content_tag(:div, :class => "menu-more-container #{options.delete(:menu_more_container_class)}") do
            s = ''
            s << content_tag(:a, options[:label] || l(:label_menu_more), :onclick => "ToggleDiv('menu-more-#{menu.object_id.to_s}'); #{options.delete(:menu_expander_after_function_js)}", :class => "menu-expander #{options.delete(:menu_expander_class)}")
            s << content_tag(:div, content_tag('ul', html_links.html_safe), :id => "menu-more-#{menu.object_id.to_s}", :class => "menu-more collapsed #{options.delete(:menu_more_class)}", :style => 'display:none')
            s.html_safe
          end
        end

        def project_heading(project, sub_item_text)
          #          if project
          #            "#{project.name} - #{sub_item_text}"
          #          else
          return "#{sub_item_text}".html_safe
          #          end
        end

        def render_project_heading(project, sub_item_text = nil)
          if sub_item_text.nil?
            item = Redmine::MenuManager.items(:project_menu).detect {|i| i.name == current_menu_item}
            sub_item_text = item.caption if item
          end
          ctx_view_projects_show_project_heading = {:additional_heading => '', :project => project, :contextual_heading => ''}
          Redmine::Hook.call_hook(:view_projects_show_project_heading, ctx_view_projects_show_project_heading)
          additional_heading = content_tag(:div, ctx_view_projects_show_project_heading[:additional_heading].html_safe, :class => 'additional-heading') if ctx_view_projects_show_project_heading[:additional_heading].to_s.size > 0
          contextual_heading = content_tag(:div, ctx_view_projects_show_project_heading[:contextual_heading].html_safe, :class => 'contextual') if !ctx_view_projects_show_project_heading[:contextual_heading].blank?
          ((contextual_heading || '') + content_tag('h2', project_heading(project, sub_item_text.to_s) + additional_heading.to_s)).html_safe
        end

        def project_header_breadcrump(options={})
          breadcrump = Array.new
          breadcrump << link_to(l(:label_templates_plural), {:controller => 'templates', :action => 'index'}) if @project.easy_is_easy_template
          @project.self_and_ancestors.each do |project|
            project_name = h(project.name)
            project_name << " <span class=\"menu-project-template\">#{l(:label_menu_project_template)}</span>".html_safe if project.easy_is_easy_template?
            project_name << " <span class=\"menu-project-template\">#{l(:field_is_planned)}</span>".html_safe if project.is_planned
            if @project.id == project.id
              breadcrump << content_tag( :h1, link_to(project_name, url_to_project(project), {:class => 'self'}) )
            else
              breadcrump << link_to(project_name, url_to_project(project), {:class => 'ancestor'}) unless in_mobile_view?
            end
          end

          breadcrump << truncate_html(h(@issue.to_s), 60) if @issue && !@issue.new_record? && !in_mobile_view?

          return breadcrump.join(' &#187; ').html_safe
        end

        def url_to_entity(entity, options={})
          case entity.class.name
          when 'Attachment'
            url_to_attachment(entity, options)
          when 'Document'
            url_to_document(entity, options)
          when 'Issue'
            url_to_issue(entity, options)
          when 'Journal'
            url_to_journal(entity, options)
          when 'Project'
            url_to_project(entity, options)
          when 'User'
            url_to_user(entity, options)
          else
            {}
          end
        end

        def url_to_attachment(attachment, options={})
          action = options.delete(:download) ? 'download' : 'show'
          if attachment.is_a?(Attachment::Version)
            {:controller => 'attachments', :action => action, :id => attachment, :version => true, :t => attachment.updated_at.to_i, :only_path => (options[:only_path].nil? ? true : options[:only_path])}
          else
            {:controller => 'attachments', :action => action, :id => attachment, :filename => attachment.filename, :t => attachment.created_on.to_i, :only_path => (options[:only_path].nil? ? true : options[:only_path])}
          end
        end

        def url_to_document(document, options={})
          {:controller => 'documents', :action => 'show', :id => document, :only_path => (options[:only_path].nil? ? true : options[:only_path])}
        end

        def url_to_issue(issue, options={})
          issue_path(issue, :only_path => (options[:only_path].nil? ? true : options[:only_path]))
        end

        def url_to_journal(journal, options={})
          {:controller => 'issues', :action => 'show', :id => journal.issue, :anchor => "journal-#{journal.id}-notes", :only_path => (options[:only_path].nil? ? true : options[:only_path])}
        end

        def url_to_project(project, options={})
          default_project_page = EasySetting.value('default_project_page', project)
          method_name = "link_to_project_with_#{default_project_page}".to_sym
          url = send(method_name, project, options) if respond_to?(method_name)
          url ||= {:controller => 'projects', :action => 'show', :id => project}
          url_for(url.merge(options))
        end

        def url_to_user(user, options={})
          {:controller => 'users', :action => 'show', :id => user, :only_path => (options[:only_path].nil? ? true : options[:only_path])}
        end

        def link_to_project_with_project_overview(project, options = {})
          {:controller => 'projects', :action => 'show', :id => project}
        end

        def link_to_project_with_issue_tracking(project, options = {})
          {:controller => 'issues', :action => 'index', :project_id => project}
        end

        def link_to_project_with_time_tracking(project, options = {})
          {:controller => 'timelog', :action => 'index', :project_id => project}
        end

        def link_to_project_with_news(project, options = {})
          {:controller => 'news', :action => 'index', :project_id => project}
        end

        def link_to_project_with_documents(project, options = {})
          {:controller => 'documents', :action => 'index', :project_id => project}
        end

        def link_to_project_with_roadmap(project, options = {})
          {:controller => 'versions', :action => 'index', :project_id => project}
        end

        def link_to_project_with_repository(project, options = {})
          {:controller => 'repositories', :action => 'show', :id => project}
        end

        def link_to_project_with_boards(project, options = {})
          {:controller => 'boards', :action => 'index', :project_id => project}
        end

        def link_to_project_with_files(project, options = {})
          {:controller => 'files', :action => 'index', :project_id => project}
        end

        def link_to_project_with_wiki(project, options = {})
          {:controller => 'wiki', :action => 'show', :project_id => project}
        end

        def link_to_project_with_calendar(project, options = {})
          {:controller => 'calendars', :action => 'show', :project_id => project}
        end

        def link_to_project_with_gantt(project, options = {})
          {:controller => 'gantts', :action => 'show', :project_id => project}
        end

        # Return *true* if item can be added to select
        def eqeoc(key, field, options)
          options ||= {}
          return false if options[:field_disabled_options] && [options[:field_disabled_options][field]].flatten.include?(key)
          return ( options[:extended_options] && options[:extended_options].include?(key) ) ||
            ((options[:option_limit] && options[:option_limit][key] && options[:option_limit][key].include?(field)) )
        end

        def get_scoped_options_for_select(named_scope, selected=nil, name_method=nil, id_method=nil)
          name_method ||= 'to_s'.to_sym
          id_method ||= 'id'.to_sym

          named_scope_array = named_scope.collect do |entry|
            if name_method.is_a?(Symbol)
              name = entry.send(name_method).to_s
            elsif name_method.is_a?(Proc)
              name = name_method.call(entry).to_s
            end

            if id_method.is_a?(Symbol)
              id = entry.send(id_method).to_s
            elsif id_method.is_a?(Proc)
              id = id_method.call(entry).to_s
            end

            [name, id]
          end
          options_for_select(named_scope_array, selected)
        end

        def scoped_easy_select_tag(name, named_scope, selected_value=nil, load_data_url=nil, options={})
          raise "scoped_easy_select_tag -> named_scope has to be ActiveRecord::Relation! (instead of #{named_scope.class.name})" if named_scope.class != ActiveRecord::Relation

          if options.delete(:force_autocomplete)
            values = nil
          elsif options.delete(:force_select)
            values = get_scoped_options_for_select(named_scope, (selected_value && selected_value[:id]), options.delete(:name), options.delete(:id))
          else
            named_scope_count = named_scope.count
            values = named_scope_count > EasySetting.value('easy_select_limit') ? nil : get_scoped_options_for_select(named_scope, (selected_value && selected_value[:id]), options.delete(:name), options.delete(:id))
          end

          easy_select_tag(name, selected_value || {:name => '', :id => ''}, values, load_data_url, options)
        end

        def easy_select_tag(name, selected_value, values=nil, load_data_url=nil, options={})
          options[:onchange] ||= 'null'
          display_no_data = !options.delete(:no_label_no_data)

          if values.nil?
            easy_autocomplete_tag(name, selected_value, load_data_url, options)
          elsif values.empty?
            if display_no_data
              "<em>#{l(:label_no_data)}</em>".html_safe
            end
          else
            values.insert(0, options_for_select([['', '']])) if options[:include_blank]
            select_tag(name, values, {:onchange => options[:onchange]}.merge(options[:html_options] || {}))
          end
        end

        def easy_autocomplete_tag(name, selected_value, load_data_url, options={})
          root_element = options[:root_element].blank? ? 'null' : "'#{options[:root_element]}'"
          options[:html_options] ||= {}
          id = options[:html_options].delete(:id) || name
          ac = text_field_tag(nil, selected_value[:name], options[:html_options].merge({:id => id + '_autocomplete'}))
          ac << hidden_field_tag(name, selected_value[:id], :id => id)
          ac << javascript_tag do
            "
  $(document).ready(function() {
    easyAutocomplete('#{id}', '#{load_data_url}', function(event, ui) {#{options[:onchange]}}, #{root_element});
    })

            ".html_safe
          end
          return ac.html_safe
        end

        def easy_multiselect_tag(name, possible_values, selected_values, options={})
          options[:id] ||= sanitize_to_id(name)

          possible_values = possible_values.map{|v| v = v.to_a; {:value => v[0], :id => v[1] || v[0]}}
          selected_values = [possible_values[0][:id]] if selected_values.blank?

          html = "<span id=\"#{options[:id]}_entity_array\"></span>".html_safe
          html << text_field_tag('', '', :id => "#{options[:id]}_autocomplete")
          html << javascript_tag("easyMultiselectTag(#{options[:id].to_json}, #{name.to_json}, #{possible_values.to_json}, #{selected_values.to_json});")

          html
        end

        def top_menu_items_for_mobile
          links = []
          menu_items_for(:easy_quick_top_menu) do |node|
            next if node.name == :my_page
            links << render_menu_node(node)
          end
          menu_items_for(:top_menu) do |node|
            links << render_menu_node(node)
          end

          return links.join("\n").html_safe
        end

        def easy_color_scheme_select_tag(name, options={})
          options[:include_blank] = true if options[:include_blank].nil?
          selected = options.delete(:selected)

          l = Array.new
          l << content_tag(:p, radio_button_tag(name, '', selected.nil?) + label_tag("#{name}_", l(:label_none)), :class =>'floating colorscheme-item') if options.delete(:include_blank)
          0.upto(EasyExtensions::EasyProjectSettings.easy_color_schemes_count) do |i|
            l << content_tag(:p, radio_button_tag(name, "scheme-#{i}", "scheme-#{i}" == selected) + label_tag("#{name}_scheme-#{i}",  l(:sample_text), :class => "scheme-#{i}"), :class =>'floating color-scheme-item' + ("scheme-#{i}" == selected ? ' selected' : ''))
          end

          return content_tag(:div, l.join("\n").html_safe, :class =>'easy-color-scheme-container')
        end

        # *file_type = :csv | :pdf | :ical | ...
        # * args[0] = query | string | symbol
        # * args[1] = optional default string if query entity name is not in langfile
        def get_export_filename(file_type, *args)
          obj = args.first
          if obj.respond_to?(:entity)
            query = obj
            entity = query.entity.name
            if query.new_record?
              name = l("label_#{entity.underscore}_plural", :default => args[1] || entity.underscore.humanize)
            else
              name = query.name
            end
          else
            name = obj && l(obj, :default => obj.to_s.humanize) || 'export'
          end

          return name + ".#{file_type}"
        end

        def attachment_headers_tags
          tags = Array.new
          tags << javascript_include_tag('attachments')
          tags << javascript_include_tag('attachments_patch', :plugin => 'easy_extensions')

          return tags
        end

        def include_attachment_headers_tags
          unless @attachment_headers_tags_included
            @attachment_headers_tags_included = true
            content_for :header_tags do
              attachment_headers_tags.join.html_safe
            end
          end
        end

        def authoring_with_datetime(created, author, options={})
          l(options[:label] || :label_added_datetime_by, :author => link_to_user(author), :datetime => format_time(created)).html_safe
        end

        def format_issue_meeting_time(issue, options={})
          if issue.tracker.easy_is_meeting?
            include_date = !(issue.start_date == issue.due_date)
            format_time_range( issue.easy_start_date_time, issue.easy_due_date_time, include_date )
          end
        end

        def render_easy_sliding_panel(name, options={}, &block)

          yield panel = EasyExtensions::EasySlidingPanel.new(name, self,  options)

          render(:partial => 'common/easy_sliding_panel', :locals => {:panel => panel})
        end

        def momentjs_date_format
          case Setting.date_format
          when '%Y-%m-%d'
            'YYYY-MM-DD'
          when '%d/%m/%Y'
            'DD/MM/YYYY'
          when '%d.%m.%Y'
            'DD.MM.YYYY'
          when '%d-%m-%Y'
            'DD-MM-YYYY'
          when '%m/%d/%Y'
            'MM/DD/YYYY'
          when '%d %b %Y'
            'DD MMM YYYY'
          when '%d %B %Y'
            'DD MMMM YYYY'
          when '%b %d, %Y'
            'MMM DD, YYYY'
          when '%B %d, %Y'
            'MMMM DD, YYYY'
          else
            'D. M. YYY'
          end
        end

        def momentjs_locale
          case I18n.locale
          when :'pt-BR'
            'pt-br'
          when :zh
            'zh-cn'
          when :'zh-TW'
            'zh-tw'
          else
            I18n.locale.to_s
          end
        end

        def convert_form_name_to_id(name)
          name.gsub(/\[/,'_').gsub(/\]/,'')
        end

        def render_reorder_handle(obj_or_url, name, options={})
          url = obj_or_url.is_a?(String) ? obj_or_url : polymorphic_url(obj_or_url)

          content_tag(:span, '', {:data => {:url => url, :name => name},:class => 'icon-reorder easy-sortable-list-handle', :title => l(:title_reorder_button)}.reverse_merge(options))
        end

        def include_jqplot_scripts
          unless @include_jqplot_scripts_added
            content_for :header_tags do
              stylesheet_link_tag('jquery.jqplot.min.css', :media => 'all', :plugin => 'easy_extensions') +
                '<!--[if IE]>'.html_safe + javascript_include_tag('jqplot/excanvas.min.js', :plugin => 'easy_extensions') + '<![endif]-->'.html_safe +
                javascript_include_tag('jqplot/jquery.jqplot.min.js',
                'jqplot/plugins/jqplot.json2.min.js',
                'jqplot/plugins/jqplot.barRenderer.min.js',
                'jqplot/plugins/jqplot.pieRenderer.min.js',
                'jqplot/plugins/jqplot.enhancedLegendRenderer.min.js',
                'jqplot/plugins/jqplot.categoryAxisRenderer.min.js',
                'jqplot/plugins/jqplot.dateAxisRenderer.min.js',
                'jqplot/plugins/jqplot.highlighter.min.js',
                'jqplot/plugins/jqplot.pointLabels.min.js',
                :plugin => 'easy_extensions')
            end
          end
        end

        def include_google_maps_scripts(options = {})
          unless @include_google_maps_scripts_added
            if options[:callback]
              callback_params = "&callback=#{options[:callback]}"
            else
              callback_params = ''
            end
            if options[:key]
              key_params = "&key=#{options[:key]}"
            else
              key_params = ''
            end

            content_for :header_tags do
              "<script type=\"text/javascript\" src=\"#{Setting.protocol}://maps.googleapis.com/maps/api/js?v=3&sensor=false#{callback_params}#{key_params}\"></script>\n".html_safe +
                "<script type=\"text/javascript\" src=\"#{Setting.protocol}://google-maps-utility-library-v3.googlecode.com/svn/trunk/markerclusterer/src/markerclusterer_compiled.js\"></script>\n".html_safe
            end
            @include_google_maps_scripts_added = true
          end
        end

        # generates an encoding select tag, if given selector_id of containing tag, it selects probably encoding depending on platform
        def easy_encoding_select_tag(selector_id = nil, html_options={})
          tag = label_tag(:encoding) + select_tag(:encoding, options_for_select(%w(UTF-8 windows-1250 ISO-8859-2)), html_options)
          js = ''
          if selector_id
            js << '<script type="text/javascript"> '
            js << 'check_widle = /.?(win).?/i; '
            js << 'if (check_widle.test(navigator.platform)) { '
            js << "  $(\"##{selector_id} select\").val(\"windows-1250\"); "
            js << '}; </script>'
          end
          tag.html_safe + js.html_safe
        end

      end
    end

    module InstanceMethods

      def checked_image_with_easy_extensions(checked=true)
        if checked
          return(content_tag(:i, '', :class => 'icon-checked', :title => l(:general_text_Yes)))
        end
      end

      # Renders flash messages
      def render_flash_messages_with_easy_extensions
        s = ''
        flash.each do |k,v|
          s << content_tag(:div, content_tag(:span, v ) + link_to_function('', "$(this).closest('.flash').fadeOut(500, function(){$(this).remove()})", :class => 'icon icon-close'), :class => "flash #{k}")
        end
        s.html_safe
      end

      def link_to_project_with_easy_extensions(project, options={}, html_options = {})
        if project.archived?
          h(project)
        else
          project_name = options.delete(:family_name) ? h(project.family_name) : h(project)
          link_to(project_name, url_to_project(project, options), {:title => h(project)}.merge(html_options))
        end
      end

      # Displays a link to user's account page if active
      def link_to_user_with_easy_extensions(user, options={})
        if user.is_a?(User)
          name = h(user.name(options[:format]))
          if user.active? || (User.current.admin? && user.logged?)
            link = link_to(name, url_to_user(user, options), :class => user.css_classes, :title => l(:title_user_detail))

            if EasyAttendance.enabled? && options[:only_path].nil? && !User.current.in_mobile_view?
              easy_attendace_indicator_css = 'user easy-attendance-indicator'
              if user.last_today_attendance && user.last_today_attendance.easy_attendance_activity.at_work?
                easy_attendace_indicator_css << ' online'
                easy_attendance_indicator = user.last_today_attendance.easy_attendance_activity.name
              else
                easy_attendace_indicator_css << ' offline'
                if user.last_today_attendance
                  easy_attendance_indicator = user.last_today_attendance.easy_attendance_activity.name
                else
                  easy_attendance_indicator = l(:label_easy_instant_message_offline)
                end
              end
              hook_context = {:user => user, :easy_attendance_indicator => easy_attendance_indicator, :easy_attendace_indicator_css => easy_attendace_indicator_css}
              easy_attendance_indicator = call_hook(:helper_application_link_to_user_in_easy_attendance, hook_context)

              link << content_tag(:small, easy_attendance_indicator, :class => easy_attendace_indicator_css)
            end

            content_tag(:span, link, :class => 'nowrap')
          else
            content_tag(:span, h(user.to_s), :class => 'user-name')
          end
        else
          content_tag(:span, h(user.to_s), :class => 'user-name')
        end
      end

      def link_to_attachment_with_easy_extensions(attachment, options={})
        text = options.delete(:text) || attachment.filename
        opt_only_path = {}
        opt_only_path[:only_path] = (options[:only_path] == false ? false : true)
        options.delete(:only_path)
        options[:target] = '_blank' unless options.key?(:target)
        link_url_options = (options.delete(:url) || {}).merge(opt_only_path)

        link_to(h(text), url_to_attachment(attachment, options).merge(link_url_options), {:title => l(:title_download_attachment)}.merge(options))
      end

      def format_activity_description_with_easy_extensions(text)
        truncate_html(text.to_s, 120).html_safe
      end

      def project_tree_options_for_select_with_easy_extensions(projects, options = {}, &block)
        s = ''

        ancestors = Array.new
        ancestor_conditions = projects.collect{|project| "(#{Project.left_column_name} < #{project.left} AND #{Project.right_column_name} > #{project.right})"}
        if ancestor_conditions.any?
          ancestor_conditions = "(#{ancestor_conditions.join(' OR ')}) AND (projects.id NOT IN (#{projects.collect(&:id).join(',')}))"
          ancestors = Project.find(:all, :conditions => ancestor_conditions)
        end

        projects << ancestors

        project_tree(projects.flatten.uniq) do |project, level|
          name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '').html_safe
          selected_value = project

          unless options.empty?
            if (options[:selected].is_a?(Array) && options[:selected].size > 0)
              first_item = options[:selected].first
              selected_value = (first_item.is_a?(String) ? project.id.to_s : project.id) if first_item.class != project.class
            elsif (!options[:selected].blank? && !options[:selected].is_a?(Array))
              if (options[:selected].is_a?(Project) && options[:selected].id == project.id)
                selected_value = options[:selected]
              elsif (options[:selected].is_a?(String) && options[:selected] == project.id.to_s)
                selected_value = options[:selected]
              end
            end

            tag_options = {:value => project.id, :selected => (option_value_selected?(selected_value, options[:selected]) ? 'selected' : nil)}
          else
            tag_options = {:value => project.id, :selected => nil}
          end

          if ancestors.include?(project)
            tag_options[:style] = 'font-style:italic'
            tag_options[:disabled] = true
          end
          tag_options.merge!(yield(project)) if block_given?

          s << content_tag('option', (name_prefix + h(project)).html_safe, tag_options)
        end

        unless options.empty?
          if options[:include_blank]
            s = "<option value=\"\">#{options[:include_blank] if options[:include_blank].kind_of?(String)}</option>\n" + s
          end
          if options[:selected].blank? && options[:prompt]
            prompt = options[:prompt].kind_of?(String) ? options[:prompt] : I18n.translate('support.select.prompt', :default => 'Please select')
            s = "<option value=\"\">#{prompt}</option>\n" + s
          end
        end

        s.html_safe
      end

      def breadcrumb_with_easy_extensions(*args)
        elements = args.flatten
        elements.any? ? content_tag('p', args.join(' &#187; ').html_safe, :class => 'breadcrumb') : nil
      end

      def link_to_issue_with_easy_extensions(issue, options={})
        return '' if issue.nil?
        title = nil
        subject = nil
        text = ''
        if options[:tracker] != false
          text << "#{issue.tracker} "
        end
        if EasySetting.value('show_issue_id', issue.project)
          text << "##{issue.id}"
        end
        if options[:subject] == false
          title = truncate(issue.subject, :length => 60)
        else
          subject = issue.subject
          if options[:truncate]
            subject = truncate(subject, :length => options[:truncate])
          end
        end
        if subject
          text << ': ' unless text.blank?
          text << subject
        end
        if issue.new_record?
          s = text
        else
          s = link_to(text, url_to_issue(issue, options), {:class => issue.css_classes, :title => title}.merge(options[:html] || {}))
        end
        s = "#{ERB::Util.h(issue.project)} - " + s if options[:project]
        s.html_safe
      end

      def progress_bar_with_easy_extensions(pcts, options={})
        pcts = [pcts, pcts] unless pcts.is_a?(Array)
        pcts = pcts.collect(&:round)
        pcts[1] = pcts[1] - pcts[0]
        pcts << (100 - pcts[1] - pcts[0])
        width = options[:width] #|| '100px;'
        legend = options[:legend] || ''
        title = options[:title] || "#{pcts.first} %"
        progress_class = 'progress ' + (options[:progress_class] || '')
        progress_class << " progress-#{pcts[0]}"
        content_tag('table',
          content_tag('tr',
            (pcts[0] > 0 ? content_tag('td', '', :style => "width: #{pcts[0]}%;", :class => 'closed') : ''.html_safe) +
              (pcts[1] > 0 ? content_tag('td', '', :style => "width: #{pcts[1]}%;", :class => 'done') : ''.html_safe) +
              (pcts[2] > 0 ? content_tag('td', '', :style => "width: #{pcts[2]}%;", :class => 'todo') : ''.html_safe)
          ), :class => progress_class, :style => "width: #{width};", :title => title).html_safe +
          content_tag('p', legend, :class => 'percent').html_safe
      end

      def toggle_link_with_easy_extensions(name, id, options={})
        onclick = "$('##{id}').toggle(); "
        onclick << (options[:focus] ? "$('##{options[:focus]}').focus(); " : "this.blur(); ")
        onclick << "return false;"
        link_to(name, "#", {:onclick => onclick}.merge(options))
      end

      def principals_check_box_tags_with_easy_extensions(name, principals)
        s = ''
        principals.each do |principal|
          s << "<label class=\"#{principal.class.name.underscore}\">#{ check_box_tag name, principal.id, false, :id => nil }<span>#{h principal}</span></label>\n"
        end
        s.html_safe
      end

      def other_formats_links_with_easy_extensions(options={})
        if options[:no_container]
          yield Redmine::Views::OtherFormatsBuilder.new(self)
        else
          concat('<div class="other-formats">'.html_safe)
          yield Redmine::Views::OtherFormatsBuilder.new(self)
          concat('</div>'.html_safe)
        end
      end

      def avatar_with_easy_extensions(user, options = {})
        return avatar_without_easy_extensions(user, options) if Setting.gravatar_enabled?
        return '' if !EasySetting.value('avatar_enabled')

        no_link = options.delete(:no_link)
        options[:size] ||= '64'
        av = user.easy_avatar if user.respond_to?(:easy_avatar)
        if av.present?
          img_tag = image_tag(easy_avatar_url(:file_name => av, :format => 'png'), :class => 'gravatar', :width => options[:size], :height => options[:size], :alt => user.to_s)
        else
          if Setting.gravatar_default.blank?
            img_tag = image_tag('avatar.jpg', :plugin => 'easy_extensions', :class => 'gravatar', :width => options[:size], :height => options[:size], :alt => user.to_s)
          else
            options.merge!({:ssl => (request && request.ssl?), :default => Setting.gravatar_default})
            email = nil
            if user.respond_to?(:mail)
              email = user.mail
            elsif user.to_s =~ %r{<(.+?)>}
              email = $1
            end
            img_tag = gravatar(email.to_s.downcase, options) unless email.blank? rescue nil
          end
        end
        if no_link || !user.is_a?(User)
          content_tag('div', img_tag, :class => 'avatar-container')
        else
          content_tag('div', link_to(img_tag, {:controller => 'users', :action => 'show', :id => user}, :title => l(:title_user_profile, :username => user.name)), :class => 'avatar-container')
        end
      end

      # Renders the project quick-jump box
      def render_project_jump_box_with_easy_extensions
        easy_select_tag('quick_navigation', {:id => ''}, nil,
          url_for(:controller => 'easy_auto_completes', :action => 'my_projects', :format => 'json', :jump => current_menu_item),
          {:include_blank => true, :root_element => 'projects', :no_label_no_data => true, :force_autocomplete => true,
            :onchange => 'sel_val = $(\'#quick_navigation\').val(); if (sel_val != null && sel_val.length > 0) {window.location = sel_val;}',
            :html_options => {:type=>'search',:placeholder => l(:label_jump_to_a_project), :title => l(:title_jump_to_project), :accesskey => Redmine::AccessKeys.key_for(:project_jump), :onfocus => '$(\'#quick_navigation_autocomplete\').val(\'\');'}
          }
        )
      end

      def authorize_for_with_easy_extensions(controller, action, project = @project)
        User.current.allowed_to?({:controller => controller, :action => action}, project)
      end

      def render_tabs_with_easy_extensions(tabs, show_tabs_if_only_one = true)
        if tabs.any?
          if show_tabs_if_only_one || tabs.size > 1
            render :partial => 'common/tabs', :locals => {:tabs => tabs}
          else
            tab = tabs.first
            render :partial => tab[:partial], :locals => {:tab => tab}
          end
        else
          content_tag 'p', l(:label_no_data), :class => "nodata"
        end
      end

      def html_title_with_easy_extensions(*args)
        if args.empty?
          title = []
          title << @project.name if @project
          title.concat(@html_title || [])
          title << Setting.app_title unless Setting.app_title == title.last
          title.reject(&:blank?).join(' - ')
        else
          @html_title ||= []
          @html_title += args
        end
      end

      def body_css_classes_with_easy_extensions
        css = body_css_classes_without_easy_extensions
        css << ' easy-mobile-view' if in_mobile_view?
        css << ' non-easy-redmine-theme' if current_theme.nil? || !current_theme.is_easy_theme?

        return css
      end

      def context_menu_with_easy_extensions(url, container='table.list')
        unless @context_menu_included
          content_for :header_tags do
            stylesheet_link_tag('context_menu')
          end
          if l(:direction) == 'rtl'
            content_for :header_tags do
              stylesheet_link_tag('context_menu_rtl')
            end
          end
          @context_menu_included = true
        end

        javascript_tag( "$(document).ready(function() {contextMenuInit('#{ url_for(url) }', $('#{container}'))})") if url
      end

      def current_theme_with_easy_extensions
        unless instance_variable_defined?(:@current_theme)
          @current_theme = User.current.current_theme
        end
        @current_theme
      end

      def preview_link_with_easy_extensions(url, form, target='preview', options={})
        if Setting.text_formatting == 'HTML'
          ''
        else
          preview_link_without_easy_extensions(url, form, target, options)
        end
      end

      def sidebar_content_with_easy_extensions?
        (sidebar_content_without_easy_extensions? || content_for?(:easy_page_layout_service_box)) && EasyExtensions.render_sidebar?(params[:controller], params[:action], params)
      end

      def thumbnail_tag_with_easy_extensions(attachment, options={})
        link_to image_tag(thumbnail_path(attachment)),
          named_attachment_path(attachment, attachment.filename),
          {:title => attachment.filename}.merge(options)
      end

      def include_calendar_headers_tags_with_easy_extensions
        unless @calendar_headers_tags_included
          tags = javascript_include_tag("datepicker")
          @calendar_headers_tags_included = true
          content_for :header_tags do
            start_of_week = Setting.start_of_week
            start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
            # Redmine uses 1..7 (monday..sunday) in settings and locales
            # JQuery uses 0..6 (sunday..saturday), 7 needs to be changed to 0
            start_of_week = start_of_week.to_i % 7

            tags << javascript_tag(
              "var datepickerOptions={dateFormat: 'yy-mm-dd', firstDay: #{start_of_week}, " +
                " onSelect: function(dateText, inst){$('#'+ inst.id).change()},"+
                "showOn: 'button', buttonImageOnly: false, buttonText: 'C', "+
                "showButtonPanel: true, showWeek: true, showOtherMonths: true, selectOtherMonths: true, changeMonth: true, changeYear: true, beforeShow: beforeShowDatePicker};")
            jquery_locale = l('jquery.locale', :default => current_language.to_s)
            unless jquery_locale == 'en'
              tags << javascript_include_tag("i18n/jquery.ui.datepicker-#{jquery_locale}.js")
              if jquery_locale == 'cs'
                tags << javascript_tag("$(document).ready(function() {$.datepicker.regional['cs'].currentText = '#{(l(:label_today)).humanize}';$.datepicker.setDefaults($.datepicker.regional['cs']);})")
              end
            end
            tags
          end
        end
      end

      def stylesheet_link_tag_with_easy_extensions(*sources)
        s = sources.dup

        unless controller.nil?
          options = s.last.is_a?(Hash) ? s.pop : {}
          plugin = options[:plugin]
          s = s.map do |source|
            if plugin
              controller.used_stylesheets("/plugin_assets/#{plugin}/stylesheets/#{source}")
            elsif current_theme && current_theme.stylesheets.include?(source)
              controller.used_stylesheets(current_theme.stylesheet_path(source))
            else
              controller.used_stylesheets(File.join('/stylesheets', source))
            end
          end

        end

        stylesheet_link_tag_without_easy_extensions(*sources)
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyPatch::ApplicationHelperPatch'
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'ModalSelectorTagsHelper'
