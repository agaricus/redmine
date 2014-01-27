module EasyPatch
  module UserCustomFieldPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        class << self

          def customized_class
            Principal
          end

        end

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'UserCustomField', 'EasyPatch::UserCustomFieldPatch'
