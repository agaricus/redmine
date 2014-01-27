module EasyBudgetsheet
  module EasySettingPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        class << self

          alias_method_chain :boolean_keys, :easy_budgetsheet

        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def boolean_keys_with_easy_budgetsheet
        k = boolean_keys_without_easy_budgetsheet
        k << :show_billable_things
        k << :billable_things_default_state
        k
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasySetting', 'EasyBudgetsheet::EasySettingPatch'
