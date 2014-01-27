module EasyPatch
  module IssueCategoryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        safe_attributes 'parent_id'

        acts_as_nested_set :order => 'name', :dependent => :destroy, :scope => 'project_id'
      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'IssueCategory', 'EasyPatch::IssueCategoryPatch'
