module EasyPatch
  module ActsAsUserReadable

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_user_readable(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsUserReadable::ActsAsUserReadableMethods)

        cattr_accessor :user_readable_options
        self.user_readable_options = {}
        
        send(:include, EasyPatch::ActsAsUserReadable::ActsAsUserReadableMethods)
      end

    end

    module ActsAsUserReadableMethods

      def self.included(base)
        base.class_eval do

          has_many :user_read_records, :as => :entity, :class_name => 'EasyUserReadEntity', :dependent => :destroy

          after_create :mark_as_read

          def unread?(user = nil)
            user ||= User.current
            !user_read_records.where( :user_id => user.id ).exists? if EasyUserReadEntity.table_exists?
          end

          def mark_as_read(user = nil)
            user ||= User.current
            user_read_records.create( :user_id => user.id ) if EasyUserReadEntity.table_exists? && unread?(user)
          end

        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsUserReadable'
