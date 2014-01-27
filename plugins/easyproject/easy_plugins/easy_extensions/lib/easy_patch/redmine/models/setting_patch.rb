module EasyPatch
  module SettingPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :value, :easy_extensions

        class << self

          Redmine::Plugin.all.each do |plugin|
            available_settings_key = "plugin_#{plugin.id}"
            next if !plugin.settings || Setting.available_settings.key?(available_settings_key)
            Setting.available_settings[available_settings_key] = {'default' => plugin.settings[:default], 'serialized' => true}

            src = <<-END_SRC
    def #{available_settings_key}
      self[:#{available_settings_key}]
    end

    def #{available_settings_key}?
      self[:#{available_settings_key}].to_i > 0
    end

    def #{available_settings_key}=(value)
      self[:#{available_settings_key}] = value
    end
            END_SRC
            class_eval src, __FILE__, __LINE__
          end
        end

        remove_validation :name, 'validates_uniqueness_of'
        remove_validation :name, 'validates_inclusion_of'

        validates_uniqueness_of :name
        validates_inclusion_of :name, :in => Setting.available_settings.keys

      end
    end

    module InstanceMethods

      def value_with_easy_extensions
        v = value_without_easy_extensions
        if v.is_a?(Hash) && !v.is_a?(ActiveSupport::HashWithIndifferentAccess)
          ActiveSupport::HashWithIndifferentAccess.new(v)
        else
          v
        end
      end

    end

    module ClassMethods
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Setting', 'EasyPatch::SettingPatch'
