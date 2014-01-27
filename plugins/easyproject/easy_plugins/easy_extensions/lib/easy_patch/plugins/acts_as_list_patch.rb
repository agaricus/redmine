module EasyPatch
  module ActsAsListPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def reorder_to_position=(pos)
          insert_at(pos.to_i)
          reset_positions_in_list
        end


      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'ActiveRecord::Acts::List::InstanceMethods', 'EasyPatch::ActsAsListPatch'
