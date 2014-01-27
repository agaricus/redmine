module EasyPatch
  module PrincipalPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        scope :non_system_flag, lambda { where(:easy_system_flag => false) }

      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Principal', 'EasyPatch::PrincipalPatch'
