module EasyPatch
  module JournalsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :render_notes, :easy_extensions

      end
    end

    module InstanceMethods

      def render_notes_with_easy_extensions(entity, journal, options={})
          content = ''
          project = entity.respond_to?(:project) && entity.project
          editable = User.current.logged? && (User.current.allowed_to?(:edit_issue_notes, project, :global => true) || (journal.user == User.current && User.current.allowed_to?(:edit_own_issue_notes, project, :global => true)))
          links = []

          if journal.notes.present?
            links << link_to(l(:button_quote),
                             {:controller => 'journals', :action => 'new', :id => entity, :journal_id => journal},
                             :remote => true,
                             :method => 'post',
                             :title => l(:button_quote),
                             :class => 'icon icon-comment') if options[:reply_links]
            links << link_to_in_place_notes_editor(l(:button_edit), "journal-#{journal.id}-notes",
                                                   { :controller => 'journals', :action => 'edit', :id => journal, :format => 'js', :back_url => options[:back_url] },
                                                      :title => l(:button_edit), :class => 'icon icon-edit') if editable

            if journal.private_notes && (User.current.id == journal.user_id || User.current.admin?)
              links << link_to(l(:button_journal_unprivate_note), public_journal_path(journal), :method => :post, :data => {:confirm => l(:text_are_you_sure)}, :title => l(:title_journal_unprivate_note), :class => 'icon icon-unlock')
            end
            if entity.is_a?(Issue)
              links << link_to(l(:button_create_issue_from_journal), new_issue_path(:issue => { :project_id => entity.project, :description => journal.notes }, :subtask_for_id => entity.id), :title => l(:title_create_issue_from_journal), :class => 'icon icon-add' )
            end

            hook_context = {:links => links, :journal => journal, :project => project, :entity => entity, :options => options}
            call_hook(:helper_journal_render_notes_add_links, hook_context)
            links = hook_context[:links]
          end

          css_classes = 'wiki'

          if links.empty?
            content << content_tag(:span, '', :class => 'expander issue-journal-details-toggler')
            css_classes << ' open'
          elsif !User.current.in_mobile_view?
            content << render_menu_more(journal, project, {:menu_more_container_class => 'easy-journal-tools hide-when-print', :menu_more_class => 'manual-hide', :menu_expander_after_function_js => "$(this).toggleClass('open');", :menu_expander_class => 'icon', :label => content_tag(:i, nil, :class => 'icon-arrow')+l(:label_user_form_other_settings)}) do
              links.each{|link| concat(content_tag(:li, link))}
            end
          end
          content << textilizable(journal, :notes, {:headings => false}) if journal.notes.present?
          css_classes << ' editable' if editable

          return content_tag(:div, content.html_safe, :id => "journal-#{journal.id}-notes", :class => css_classes) unless content.blank?
        end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'JournalsHelper', 'EasyPatch::JournalsHelperPatch'
