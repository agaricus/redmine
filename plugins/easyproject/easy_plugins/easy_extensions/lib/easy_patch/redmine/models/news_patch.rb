module EasyPatch
  module NewsPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        html_fragment :description, :scrub => :strip

        searchable_options[:additional_conditions] = "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false}"

        acts_as_user_readable

        safe_attributes 'spinned'

        alias_method_chain :recipients, :easy_extensions

        class << self

        end

      end
    end

    module InstanceMethods

      def recipients_with_easy_extensions
        project.users.select{|user| self.visible?(user) && user.notify_about?(self)}.map(&:mail)
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'News', 'EasyPatch::NewsPatch'
