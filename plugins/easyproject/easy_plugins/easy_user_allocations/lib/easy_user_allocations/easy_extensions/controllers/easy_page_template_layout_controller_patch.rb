module EasyUserAllocations
  module EasyPageTemplateLayoutControllerPatch

    def self.included(base)
      base.class_eval do

        helper :easy_user_allocation_gantt
        include EasyUserAllocationGanttHelper

      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyPageTemplateLayoutController', 'EasyUserAllocations::EasyPageTemplateLayoutControllerPatch'
