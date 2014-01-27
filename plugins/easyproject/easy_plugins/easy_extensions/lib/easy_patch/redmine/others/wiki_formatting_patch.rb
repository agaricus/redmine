module EasyPatch
  module WikiFormattingPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :wikitoolbar_for, :easy_extensions

      end

    end

    module InstanceMethods

      # after_submit: html_fragment removes charcters '<' and '>' and everything after
      #   if js editor is textile => replace < to "&lt;"
      #                                      > to "&gt;"
      #
      def wikitoolbar_for_with_easy_extensions(field_id, options={})
        wiki_toolbar = wikitoolbar_for_without_easy_extensions(field_id)
        return nil if wiki_toolbar.nil?

        after_submit = %{}

        if Setting.text_formatting == 'textile'
          js_field_id = "_#{field_id.gsub('-', '_')}_val"

          after_submit << %{
            var form = $("##{field_id}").parents("form");

            form.on('submit', function(){
              var prev = $("##{field_id}").val();
              var modified = prev;

              modified = modified.replace(/\</g, "&lt;");
              modified = modified.replace(/\>/g, "&gt;");

              $("##{field_id}").val(modified);

              return true;
            });

            var #{js_field_id} = $("##{field_id}").val();

            #{js_field_id} = #{js_field_id}.replace(/&lt;/g, "<");
            #{js_field_id} = #{js_field_id}.replace(/&gt;/g, ">");

            $("##{field_id}").val(#{js_field_id});
          }
        end

        reminder_confirm = options[:attachment_reminder_message] ? options[:attachment_reminder_message] : l(:text_easy_attachment_reminder_confirm)
        reminderjs = options[:attachment_reminder] ? "$('##{field_id}').addClass('set_attachment_reminder').data('ck', false).data('reminder_words', \"#{j(Attachment.attachment_reminder_words)}\").data('reminder_confirm', '#{j(reminder_confirm)}');; " : ''
        wiki_toolbar + javascript_tag(after_submit) + javascript_tag(reminderjs)
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_other_patch ['Redmine::WikiFormatting::NullFormatter::Helper', 'Redmine::WikiFormatting::Textile::Helper'], 'EasyPatch::WikiFormattingPatch'
