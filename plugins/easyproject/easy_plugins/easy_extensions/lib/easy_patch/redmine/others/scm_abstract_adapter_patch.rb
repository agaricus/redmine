# encoding: utf-8
module EasyPatch
  module ScmAbstractAdapterPatch
    def self.included(base)

      base.class_eval do

        def changeset_branches(scmid)
          []
        end

      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Scm::Adapters::AbstractAdapter', 'EasyPatch::ScmAbstractAdapterPatch'
