module EasyPatch
  module MessagePatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        html_fragment :content, :scrub => :strip

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Message', 'EasyPatch::MessagePatch'
