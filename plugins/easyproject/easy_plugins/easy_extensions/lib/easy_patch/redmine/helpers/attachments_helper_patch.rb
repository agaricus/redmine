module EasyPatch
  module AttachmentsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :link_to_attachments, :easy_extensions

        # Options:
        #   :preloaded_reads -- if contains a collection of EasyUserReadEntity for attachments param, then it is little quicker.
        def attachment_row(attachment, options={})
          return if attachment.new_record?
          row = '<tr '
          row << 'class="hascontextmenu"' unless options[:do_not_show_context_menu]
          row << '><td'
          row << ' style="display:none;"' unless options[:show_checkboxes]
          row << ">#{check_box_tag('ids[]', attachment.id, false, :id => nil)}</td>"

          row << '<td class="doc-td-title">' + link_to_attachment(attachment.current_version, :class => 'icon icon-attachment')
          unless attachment.description.blank?
            row << h(" - #{attachment.description}")
          end
          row  << "<span class=\"size\">(#{number_to_human_size attachment.filesize})</span>"
          row << content_tag(:em, "  - v#{attachment.version} " )
          if !options[:unread] &&
              ( options[:preloaded_reads] ? !options[:preloaded_reads].detect{|read| read.user_id == User.current.id && read.entity_type == attachment.current_version.class.name && read.entity_id == attachment.current_version.id } : attachment.current_version.unread?(User.current)
              )
            row << "<span class=\"unread-entity\">#{l(:label_unread_entity)}</span>"
          end
          row << '</td>'

          if options[:author]
            row << "<td><span class=\"author\">#{attachment.current_version.author}, #{format_time(attachment.current_version.updated_at)}</span></td>"
          end

          row << '<td class="fast-icons">'
          row << content_tag(:span, '', :class => 'btn_contextmenu_trigger icon icon-list', :id => "btn-attachment-#{attachment.id}", :title => l(:button_attachment_context_menu)) unless options[:do_not_show_context_menu]
          if options[:deletable]
            row << link_to('', {:controller => 'attachments', :action => 'destroy', :id => attachment},
              :data => {:confirm => l(:text_are_you_sure)},
              :method => :delete,
              :class => 'icon icon-del',
              :title => l(:button_delete))
          end
          row << '</td></tr>'

          row.html_safe
        end

        def load_reads_for_attachments( attachments, klass = 'Attachment::Version', user = nil )
          user ||= User.current
          ids = attachments.collect{ |a| a.current_version.id } if klass =~ /::Version$/
          ids ||= attachments.collect{ |a| a.id }
          EasyUserReadEntity.where(:entity_id => ids, :entity_type => klass, :user_id => user.id ).all
        end
      end

    end

    module InstanceMethods

      # Displays view/delete links to the attachments of the given object
      # Options:
      #   :author -- author names are not displayed if set to false
      def link_to_attachments_with_easy_extensions(container, options = {})
        options.assert_valid_keys(:author, :thumbnails, :category, :label, :enable_toggling, :toggling_uniq_id, :default_button_state, :show_checkboxes, :do_not_show_context_menu)

        if container.attachments.any?
          options = {:deletable => container.attachments_deletable?, :author => true}.merge(options)
          attachments = container.attachments.includes({:versions => :author}, :author)
          if options[:category]
            attachments = attachments.all.select{|attachment| attachment.category == options[:category]}
          else
            attachments = attachments.all
          end
          options[:preloaded_reads] = load_reads_for_attachments( attachments )
          render :partial => 'attachments/links', :locals => {:attachments => attachments, :options => options, :thumbnails => (options[:thumbnails] && Setting.thumbnails_enabled?)}
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'AttachmentsHelper', 'EasyPatch::AttachmentsHelperPatch'
