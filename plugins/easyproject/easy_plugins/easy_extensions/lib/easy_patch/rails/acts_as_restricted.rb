module EasyPatch
  module ActsAsRestricted

    def self.included(base)
      base.extend(ClassMethods)      
    end

    module ClassMethods

      def acts_as_restricted(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsRestricted::ActsAsRestrictedMethods)

        cattr_accessor :restricted_options
        self.restricted_options = {}

        self.restricted_options[:project] = (options.delete(:project) || :project)
        self.restricted_options[:restricted_object] = options.delete(:restricted_object)
        self.restricted_options[:easy_permission_name] = [options.delete(:easy_permission_name)].flatten.compact.collect(&:to_s)
        self.restricted_options[:if] = options.delete(:if)
        
        send(:include, EasyPatch::ActsAsRestricted::ActsAsRestrictedMethods)
      end

    end

    module ActsAsRestrictedMethods

      def self.included(base)
        base.class_eval do

          has_many :easy_permissions, :as => :entity, :class_name => 'EasyPermission', :dependent => :destroy

          class << self

            def find(*args)
              founded_results = super(*args)

              unless founded_results.nil?
                if founded_results.is_a?(Array)
                  founded_results.reject!{|r| r.active_record_restricted?}
                else
                  if founded_results.active_record_restricted?
                    founded_results = nil
                    raise(ActiveRecord::RecordNotFound)
                  end
                end
              end

              return founded_results
            end

          end

          def active_record_restricted?(user = nil, permission_names = nil, project = nil)
            user ||= User.current

            # no restriction for admin
            return false if user.admin?

            if permission_names
              permission_names = [permission_names].flatten.compact.collect(&:to_s)
            else
              permission_names = self.class.restricted_options[:easy_permission_name]
            end

            unless project
              project = send(self.class.restricted_options[:project])
            end

            # detect if condition "if" is present and evaluate it
            if self.class.restricted_options[:if].is_a?(Proc)
              apply_restricted = (self.class.restricted_options[:if].call(self) == true)
            else
              apply_restricted = true
            end

            # no restriction if condition "if" return false
            return false if !apply_restricted

            perm_obj = self.class.restricted_options[:restricted_object].nil? ? self : send(self.class.restricted_options[:restricted_object])

            # use restriction due to no object to evaluate
            return true if !perm_obj

            # no restriction if permissions are blank => no permission setted or used
            return false if permission_names.blank? || perm_obj.easy_permissions.blank?

            perms = perm_obj.easy_permissions.select{|ep| permission_names.include?(ep.name)}

            # no restriction if no permissions founded or any role list is empty => default settings
            return false if perms.blank? || perms.detect{|p| p.role_list.blank?}

            user_role_ids = user.roles_for_project(project).collect(&:id)

            allowed_role_ids = perms.collect{|p| p.role_list}.flatten.uniq.compact

            (user_role_ids & allowed_role_ids).blank?
          end

        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsRestricted'
