module EasyPatch
  module AccessControlPermissionPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        attr_accessor :acts_as_admin, :acts_as_admin_proc

        def add_actions(hash)
          hash.each do |controller, actions|
            if actions.is_a? Array
              @actions << actions.collect {|action| "#{controller}/#{action}"}
            else
              @actions << "#{controller}/#{actions}"
            end
          end
          @actions.flatten!
        end

        def permission_flags
          f = []
          f << 'r' if read?
          f << 'p' if public?
          f << 'm' if require_member?
          f << 'l' if require_loggedin?
          f
        end

        def acts_as_admin?(user=nil)
          if acts_as_admin_proc.is_a?(Proc)
            acts_as_admin_proc.call(user)
          else
            @acts_as_admin == true
          end
        end
      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessControl::Permission', 'EasyPatch::AccessControlPermissionPatch'
