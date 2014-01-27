module EasyPatch
  module CustomFieldFormatPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        ['email'].each do |name|
          define_method("format_as_#{name}") {|value|
            return value
          }
        end

      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::CustomFieldFormat', 'EasyPatch::CustomFieldFormatPatch'
