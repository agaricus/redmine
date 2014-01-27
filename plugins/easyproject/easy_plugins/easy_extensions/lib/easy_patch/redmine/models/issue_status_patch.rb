module EasyPatch
  module IssueStatusPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        acts_as_easy_translate

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'IssueStatus', 'EasyPatch::IssueStatusPatch'
