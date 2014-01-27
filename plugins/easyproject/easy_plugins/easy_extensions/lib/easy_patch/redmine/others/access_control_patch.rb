module EasyPatch
  module AccessControlPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do

        class << self

          alias_method_chain :available_project_modules, :easy_extensions

          def update_permission(name, hash, options={})
            if p = permission(name)
              p.add_actions(hash) unless hash.blank?
              p.set_options(options) unless options.blank?
            end
          end

          def permission_acts_as_admin(name, proc = nil)
            if p = permission(name)
              p.acts_as_admin = true
              p.acts_as_admin_proc = proc
            end
          end

        end

      end
    end

    module ClassMethods

      def available_project_modules_with_easy_extensions
        (available_project_modules_without_easy_extensions - EasyExtensions::EasyProjectSettings.disabled_features[:modules].collect(&:to_sym))
      end

    end

    module PermissionPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do

          alias_method_chain :initialize, :easy_extensions

          def set_options(options={})
            @public = !!options[:public] if options.key?(:public)
            @read = !!options[:read] if options.key?(:read)
            @require = options[:require] if options.key?(:require)
            @global = !!options[:global] if options.key?(:global)
          end
          
          def global?
            @global
          end

        end

      end

      module InstanceMethods
        
        def initialize_with_easy_extensions(name, hash, options)
          initialize_without_easy_extensions(name, hash, options)
          @global = !!options[:global]
        end

      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessControl', 'EasyPatch::AccessControlPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessControl::Permission', 'EasyPatch::AccessControlPatch::PermissionPatch'
