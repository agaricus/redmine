module EasyPatch
  module WikiContentPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        html_fragment :comments, :scrub => :strip

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'WikiContent', 'EasyPatch::WikiContentPatch'
