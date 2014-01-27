module EasyPatch
  module ProjectsHelperPatch
    include Redmine::Export::PDF

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :parent_project_select_tag, :easy_extensions
        alias_method_chain :project_settings_tabs, :easy_extensions

        def link_to_project_archive(project, options={})
          css = options[:class] || 'icon icon-archive'
          url = {:controller => 'projects', :action => 'archive', :id => project, :admin => '1'}.merge(options[:url] || {})
          link_to(l(:button_archive), url, :data => {:confirm => "#{project.name} \n\n #{l(:text_project_archive_confirmation)}"}, :method => :post, :class => css)
        end

        def link_to_project_unarchive(project, options={})
          css = options[:class] || 'icon icon-unlock'
          url = {:controller => 'projects', :action => 'unarchive', :id => project}.merge(options[:url] || {})
          link_to(l(:button_unarchive), url, :method => :post, :class => css)
        end

        def link_to_project_close(project, options={})
          css = options[:class] || 'icon icon-lock'
          url = {:controller => 'projects', :action => 'close', :id => project}.merge(options[:url] || {})
          link_to(l(:button_close), url, :data => {:confirm => "#{project.name} \n\n #{l(:text_project_close_confirmation)}"}, :method => :post, :class => css)
        end

        def link_to_project_reopen(project, options={})
          css = options[:class] || 'icon icon-unlock'
          url = {:controller => 'projects', :action => 'reopen', :id => project}.merge(options[:url] || {})
          link_to(l(:button_reopen), url, :data => {:confirm => "#{project.name} \n\n #{l(:text_project_reopen_confirmation)}"}, :method => :post, :class => css)
        end

        def link_to_project_copy(project, options={})
          css = options[:class] || 'icon icon-copy'
          url = {:controller => 'projects', :action => 'copy', :id => project, :admin => '1' }.merge(options[:url] || {})
          link_to(l(:button_copy), url, :class => css)
        end

        def link_to_project_delete(project, options={})
          css = options[:class] || 'icon icon-del'
          link_to(l(:button_delete), project_path(project), :method => :delete, :class => css)
        end

        def link_to_project_new_subproject(project, options={})
          css = options[:class] || 'icon icon-add'
          url = {:controller => 'projects', :action => 'new', :'project[parent_id]' => project.id, :back_url => url_for(params)}.merge(options[:url] || {})
          link_to(l(:label_subproject_new), url, :class => css, :title => l(:label_subproject_new))
        end

        def link_to_project_new_subproject_from_template(project, options={})
          css = options[:class] || 'icon icon-add'
          url = {:controller => 'templates', :action => 'index', :'project[parent_id]' => project.id, :back_url => url_for(params)}.merge(options[:url] || {})
          link_to(l(:label_new_subproject_from_template), url, :class => css, :title => l(:label_new_subproject_from_template))
        end

        def link_to_project_new_template_from_project(project, options={})
          css = options[:class] || 'icon icon-add'
          url = {:controller => 'templates', :action => 'add', :id => project, :back_url => url_for(params)}.merge(options[:url] || {})
          link_to(l(:button_new_template_from_project), url, :class => css, :title => l(:title_button_template, :projectname => project.name))
        end

        def projects_relations_field_tag(field_name, field_id, selected_values = [], options = {})
          easy_modal_selector_field_tag('Project', 'link_with_name', field_name, field_id, selected_values, options)
        end

        def render_api_project(api, project)
          api.project do
            api.id(project.id)
            api.name(project.name)
            api.description(project.description)
            api.homepage(project.homepage)
            api.parent(:id => project.parent.id, :name => project.parent.name) if project.parent && project.parent.visible?
            api.status(project.status)
            api.easy_is_easy_template(project.easy_is_easy_template)
            api.easy_start_date(project.easy_start_date) unless EasySetting.value('project_calculate_start_date', project)
            api.easy_due_date(project.easy_due_date) unless EasySetting.value('project_calculate_due_date', project)
            api.easy_external_id(project.easy_external_id)
            api.author(:id => project.author.id, :name => project.author.name, :easy_external_id => project.author.easy_external_id) if project.author

            render_api_custom_values(project.visible_custom_field_values, api)

            api.created_on project.created_on
            api.updated_on project.updated_on

            api.array :trackers do
              project.trackers.each do |tracker|
                api.tracker(:id => tracker.id, :name => tracker.name, :internal_name => tracker.internal_name, :easy_external_id => tracker.easy_external_id)
              end
            end if include_in_api_response?('trackers')

            api.array :issue_categories do
              project.issue_categories.each do |category|
                api.issue_category(:id => category.id, :name => category.name)
              end
            end if include_in_api_response?('issue_categories')
          end
        end

        def add_non_filtered_projects(options={})
          if @query && @projects && !apply_sort?(@query)
            ancestors = []
            ancestor_conditions = @projects.collect{|project| "(#{Project.left_column_name} < #{project.left} AND #{Project.right_column_name} > #{project.right})"}
            if ancestor_conditions.any?
              ancestor_conditions = "(#{ancestor_conditions.join(' OR ')})  AND (projects.id NOT IN (#{@projects.collect(&:id).join(',')}))"
              ancestor_conditions << " AND #{Project.table_name}.parent_id IS NOT NULL" if options[:exclude_roots]
              ancestors = Project.find(:all, :conditions => ancestor_conditions)
            end

            ancestors.each do |p|
              p.nofilter = ' nofilter'
            end
            @projects << ancestors
            if @query.grouped?
              @projects = @projects.flatten.uniq.sort_by{|i| @query.group_by_column.name.to_s}
            else
              @projects = @projects.flatten.uniq.sort_by(&:lft)
            end
          end
        end

        # EXPORT CSV
        def projects_to_csv(projects, query)
          encoding = l(:general_csv_encoding)
          export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
            # csv header fields
            headers = Array.new
            columns = Array.new
            query.columns.each do |c|
              if c.name == :name && !query.grouped?
                columns << EasyQueryColumn.new(:family_name,:sortable => "#{Project.table_name}.name")
              else
                columns << c
              end
              headers << c.caption
            end
            csv << headers.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
            # csv lines
            projects_list = Array.new
            if apply_sort?(query) || query.grouped?
              projects_list = projects
            else
              projects_list = projects.sort_by(&:lft)
            end
            projects_list.each do |project|
              fields = Array.new
              columns.each do |column|
                fields << format_value_for_export(project, column)
              end
              csv << fields.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
            end

          end
          return export
        end

        # EXPORT PDF
        def projects_to_pdf(projects,query)
          pdf = ITCPDF.new(current_language)
          pdf.SetTitle(l(:label_project_plural))
          pdf.alias_nb_pages
          pdf.footer_date = format_date(Date.today)
          pdf.AddPage("C")

          # title
          pdf.SetFontStyle('B',11)
          pdf.RDMCell(190,10, l(:label_project_plural))
          pdf.Ln

          row_height    = 5

          col_width = Array.new

          query.columns.each do |column|
            case column.name
            when :status
              col_width << 0.5
            when :family_name, :name
              col_width << 1.5
            when :description
              col_width << 2
            else
              col_width << 0.7
            end
          end
          ratio = 262.0 / col_width.inject(0) {|s,w| s += w}
          col_width = col_width.collect {|w| w * ratio}

          # headers
          pdf.SetFontStyle('B',8)
          pdf.SetFillColor(230, 230, 230)
          columns = Array.new
          query.columns.each do |column|
            if column.name == :name && !query.grouped?
              columns << EasyQueryColumn.new(:family_name,:sortable => "#{Project.table_name}.name")
            else
              columns << column
            end
            pdf.RDMCell(col_width[query.columns.index(column)], row_height, column.caption.to_s, 1, 0, 'L', 1)
          end
          pdf.Ln

          #rows
          pdf.SetFontStyle('',8)
          pdf.SetFillColor(255, 255, 255)

          projects_list = Array.new
          if apply_sort?(query) || query.grouped?
            projects_list = projects
          else
            projects_list = projects.sort_by(&:lft)
          end
          previous_group = false
          projects_list.each do |project|
            # group_by option
            if query.grouped? && (group = query.group_by_column.value(project)) != previous_group
              pdf.SetFontStyle('B',9)
              pdf.RDMCell(262, row_height,
                (group.blank? ? 'None' : group.to_s) + " (#{query.entity_count_by_group[group]})",
                1, 1, 'L')
              pdf.SetFontStyle('',8)
              previous_group = group
            end

            col_values = Array.new
            columns.each do |column|
              if column.name == :family_name && !query.grouped?
                col_values << project.family_name(:self_only => true, :prefix => ' ', :separator => ' ')
              else
                col_values << format_value_for_export(project, column)
              end
            end

            # Find biggest cell - his height<int>
            max_height = get_max_cell_height(columns, col_values, col_width) * row_height

            base_x = pdf.GetX
            base_y = pdf.GetY
            # make new page if it doesn't fit on the current one
            space_left = pdf.GetPageHeight - base_y - pdf.GetBreakMargin();
            if max_height > space_left
              pdf.AddPage('C')
              base_x = pdf.GetX
              base_y = pdf.GetY
              pdf.Line(base_y, base_y, col_width.sum, base_y)
            end

            columns.each_with_index do |column, i|
              pdf.SetFontStyle('',8)
              if  column.name == :family_name && !query.grouped?
                pdf.SetFontStyle('B',7) if !project.child? && !apply_sort?(query)
                pdf.SetFontStyle('BI',7) if project.css_project_classes.include?(' nofilter')
                pdf.RDMMultiCell(col_width[i], row_height, col_values[i],0, 'L', 0, 0)
              else
                pdf.RDMMultiCell(col_width[i], row_height, col_values[i],0, 'L', 0, 0)
              end
            end
            projects_to_pdf_draw_borders(pdf, base_x, base_y, base_y + max_height, col_width)
            pdf.Ln(max_height)
          end

          pdf.Output
        end

        # Draw lines to close the row (MultiCell border drawing in not uniform)
        def projects_to_pdf_draw_borders(pdf, top_x, top_y, lower_y, col_widths)
          col_x = top_x
          col_widths.each do |width|
            col_x += width
            pdf.Line(col_x, top_y, col_x, lower_y)  # columns right border
          end
          pdf.Line(top_x, top_y, top_x, lower_y)    # left border
          pdf.Line(top_x, lower_y, col_x, lower_y)  # bottom border
        end

        def get_max_cell_height( columns, col_values, col_width)
          tmp_pdf = ITCPDF.new(current_language)
          tmp_pdf.SetTitle(l(:label_project_plural))
          tmp_pdf.alias_nb_pages
          tmp_pdf.footer_date = format_date(Date.today)
          tmp_pdf.AddPage("C")
          tmp_pdf.SetFontStyle('',8)
          tmp_pdf.SetFillColor(255, 255, 255)
          max_height = 1
          base_y = tmp_pdf.GetY

          columns.each_with_index do |column, i|
            col_x = tmp_pdf.GetX
            tmp_pdf.RDMMultiCell(col_width[i], 1, col_values[i],1, 'L', 0, 1)
            max_height = (tmp_pdf.GetY - base_y) if (tmp_pdf.GetY - base_y) > max_height
            tmp_pdf.SetXY(col_x + col_width[i], base_y);
          end

          return max_height
        end

        def apply_sort?(query)
          if (!query.sort_criteria.nil? && query.sort_criteria.size > 0)
            return true
          else
            return false
          end
        end

        def add_parent_project_to_projects_collection(projects,query)
          if !apply_sort?(query)
            final_projects_collection = []
            projects.each do |p|
              if (p.child? && !projects.include?(p.parent))
                parent = p.parent
                parent.nofilter = " nofilter"
                final_projects_collection << parent
                final_projects_collection << p
              else
                final_projects_collection << p
              end
            end
            projects = final_projects_collection.flatten.uniq.sort_by(&:lft)
          end
          return projects
        end

        def easy_version_query_additional_query_buttons(entity, options={})
          entity.css_shared = 'shared' if entity.project != @project
          s = ''
          s << link_to_if_authorized(l(:button_edit),   {:controller => 'versions', :action => 'edit', :id => entity }, :class => 'icon icon-edit').to_s
          s << link_to_if_authorized(l(:button_delete), {:controller => 'versions', :action => 'destroy', :id => entity}, :data => {:confirm => l(:text_are_you_sure)}, :method => :delete, :class => 'icon icon-del').to_s
          s.html_safe
        end

        def options_for_default_project_page(enabled_modules, selected = nil)
          default_pages = []

          default_pages << 'project_overview'
          default_pages << 'roadmap'
          unless enabled_modules.blank?
            default_pages << 'issue_tracking' if enabled_modules.include?('issue_tracking') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('issue_tracking')
            default_pages << 'time_tracking' if enabled_modules.include?('time_tracking') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('time_tracking')
            default_pages << 'news' if enabled_modules.include?('news') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('news')
            default_pages << 'documents' if enabled_modules.include?('documents') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('documents')
            default_pages << 'repository' if enabled_modules.include?('repository') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('repository')
            default_pages << 'boards' if enabled_modules.include?('boards') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('boards')
            default_pages << 'files' if enabled_modules.include?('files') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('files')
            default_pages << 'wiki' if enabled_modules.include?('wiki') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('wiki')
            default_pages << 'calendar' if enabled_modules.include?('calendar') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('calendar')
            default_pages << 'gantt' if enabled_modules.include?('gantt') && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('gantt')
          end

          call_hook(:helper_options_for_default_project_page, :default_pages => default_pages, :enabled_modules => enabled_modules, :selected => selected)

          selected ||= 'project_overview'

          options_for_select(default_pages.collect{|x| [l(:"project_default_page.#{x.to_s}"), x.to_s]}, selected)
        end

      end
    end

    module InstanceMethods
      def project_settings_tabs_with_easy_extensions
        tabs = [
          {:name => 'info', :action => :edit_project, :partial => 'projects/edit', :label => :label_information_plural, :no_js_link => true},
          {:name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural, :no_js_link => true},
          {:name => 'members', :action => :manage_members, :partial => 'projects/settings/members', :label => :label_member_plural, :no_js_link => true},
          {:name => 'versions', :action => :manage_versions, :partial => 'projects/settings/versions', :label => :label_version_plural, :no_js_link => true}
        ]
        tabs << {:name => 'categories', :action => :manage_categories, :partial => 'projects/settings/issue_categories', :label => :label_issue_category_plural} if @project.display_issue_categories?
        tabs << {:name => 'wiki', :action => :manage_wiki, :partial => 'projects/settings/wiki', :label => :label_wiki, :no_js_link => true} if @project.module_enabled?(:wiki)
        tabs << {:name => 'repositories', :action => :manage_repository, :partial => 'projects/settings/repositories', :label => :label_repository, :no_js_link => true} if @project.module_enabled?(:repository)
        tabs << {:name => 'boards', :action => :manage_boards, :partial => 'projects/settings/boards', :label => :label_board_plural, :no_js_link => true} if @project.module_enabled?(:boards)
        tabs << {:name => 'activities', :action => :manage_project_activities, :partial => 'projects/settings/activities', :label => :enumeration_activities, :no_js_link => true} if @project.module_enabled?(:time_tracking)
        tabs << {:name => 'easy_issue_timer', :action => :update_settings, :partial => 'projects/settings/easy_issue_timer_settings', :label => :label_easy_issue_timer_settings, :no_js_link => true} if @project.module_enabled?(:issue_tracking)

        tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}

        call_hook(:helper_project_settings_tabs, :project => @project, :tabs => tabs)
        return tabs
      end

      # Returns allowed parent depends on project
      # => options:
      # =>    :force => :projects or :templates
      def parent_project_select_tag_with_easy_extensions(project, options={})
        options ||= {}
        options[:html] ||= {}
        selected = project.parent
        if options[:force] == :projects && selected && selected.easy_is_easy_template?
          selected = nil
        end
        # retrieve the requested parent project
        parent_id = (params[:project] && params[:project][:parent_id]) || params[:parent_id]
        if parent_id
          selected = (parent_id.blank? ? nil : Project.find(parent_id))
        end

        html_name = options[:html].delete(:name) || 'project[parent_id]'
        html_id = options[:html].delete(:id) || 'project_parent_id'

        if project.allowed_parents_scope(options).count > EasySetting.value('easy_select_limit').to_i
          selected_value = {:id => selected.id, :name => selected.name} if selected
          selected_value ||= {:id => '', :name => ''}
          easy_autocomplete_tag(html_name, selected_value, url_for(:controller => 'projects', :action => 'load_allowed_parents', :id => project.id, :force => options.delete(:force), :format => 'json'), {:html_options => {:id => html_id}, :root_element => 'projects'})
        else
          select_options = ''
          select_options << "<option value=''>&nbsp;</option>" if project.allowed_parents(options).include?(nil)
          select_options << project_tree_options_for_select(project.allowed_parents(options).compact, :selected => selected)
          content_tag('select', select_options.html_safe, :name => html_name, :id => html_id)
        end

      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ProjectsHelper', 'EasyPatch::ProjectsHelperPatch'
