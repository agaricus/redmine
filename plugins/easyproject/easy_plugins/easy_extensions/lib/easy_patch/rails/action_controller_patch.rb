module EasyPatch
  module ActionControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :clear_easy_page_ctx_and_reset_layout

        protected

        def clear_easy_page_ctx_and_reset_layout
          @__easy_page_ctx = nil
          cur_layout = self.send(:_layout)
          self.class.layout('base') if cur_layout && cur_layout.is_a?(String) && cur_layout.start_with?('easy_page_layouts/')
        end

      end
    end

    module InstanceMethods
      
    end
    
  end
  
end
EasyExtensions::PatchManager.register_rails_patch 'ActionController::Base', 'EasyPatch::ActionControllerPatch'
