module EasyPatch

  module MenuHelperPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :extract_node_details, :easy_extensions
        alias_method_chain :render_menu, :easy_extensions

        def render_dashboard_menu(menu, project = nil)
          menu_items = Array.new
          nil_category_name = 'others'
          menu_items_for(menu).group_by{|item| item.html_options[:menu_category]}.each_pair do |category, items|
            lis = Array.new
            items.each do |item|
              lis << render_dashboard_menu_node(item, project)
            end
            menu_items << content_tag(:fieldset, :class => "dashboard-container #{category}") do
              content_tag(:legend, l(category || nil_category_name, :scope => [:dashboard, :legends], :default => h(category))) +
                content_tag(:ul, lis.join("\n").html_safe, :class => "#{category || nil_category_name} menu-manager")
            end
          end

          return content_tag(:div, menu_items.join.html_safe, :class => 'menu-dashboard', :id => 'menu_' + menu.to_s)
        end

        def render_dashboard_menu_node(node, project = nil)
          caption, url, selected = extract_node_details(node, project)
          return content_tag('li', render_dashboard_menu_node_item(node, caption, url, selected), :class => selected && 'selected' || '')
        end

        def render_dashboard_menu_node_item(item, caption, url, selected)
          link_to(content_tag(:span, content_tag(:i, '', item.html_options), :class => 'dashboard-item-icon') + content_tag(:span, h(caption), :class => 'dashboard-item-label'), url)
        end

        class << self

        end

      end

    end

    module InstanceMethods

      def extract_node_details_with_easy_extensions(node, project=nil)
        item = node
        url = case item.url
        when Hash
          additional_url_params = item.param.is_a?(Proc) ? (item.param.call(project) || {}) : {}
          additional_url_params.merge(project.nil? ? item.url : {item.param => project}.merge(item.url))
        when Symbol
          send(item.url)
        else
          item.url
        end
        caption = item.caption(project)
        return [caption, url, (current_menu_item == item.name)]
      end

      def render_menu_with_easy_extensions(menu, project=nil)
        links = []
        menu_items_for(menu, project) do |node|
          links << render_menu_node(node, project)
        end
        links.empty? ? nil : content_tag('ul', links.join("\n").html_safe, :class => "menu-manager menu-#{menu.to_s.dasherize}")
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MenuManager::MenuHelper', 'EasyPatch::MenuHelperPatch'
