module EasyPatch
  module AdminHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :project_status_options_for_select, :easy_extensions
        
      end
    end

    module InstanceMethods

      def project_status_options_for_select_with_easy_extensions(selected)
        options_for_select([[l(:label_all), ''],
            [l(:project_status_active), Project::STATUS_ACTIVE.to_s],
            [l(:project_status_closed), Project::STATUS_CLOSED.to_s],
            [l(:project_status_archived), Project::STATUS_ARCHIVED.to_s],
            [l(:project_status_planned), Project::STATUS_PLANNED.to_s]
          ], selected.to_s)
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'AdminHelper', 'EasyPatch::AdminHelperPatch'
