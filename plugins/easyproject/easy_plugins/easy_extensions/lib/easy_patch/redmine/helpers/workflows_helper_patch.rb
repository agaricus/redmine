module EasyPatch
  module WorkflowsHelperPatch

    def self.included(base)

      base.class_eval do

        def tooltip_for_field(field)
          return nil unless field.is_a?(CustomField)

          if field.internal_name == 'external_mails'
            tip = l(:workflow_tooltip_text_external_mails)
            content_tag(:div, tip, :class => 'tooltiptext', :style => 'display: none;')
          end
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'WorkflowsHelper', 'EasyPatch::WorkflowsHelperPatch'
