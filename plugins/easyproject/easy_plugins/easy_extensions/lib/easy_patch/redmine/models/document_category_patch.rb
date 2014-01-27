module EasyPatch
  module DocumentCategoryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        acts_as_restricted

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'DocumentCategory', 'EasyPatch::DocumentCategoryPatch'
