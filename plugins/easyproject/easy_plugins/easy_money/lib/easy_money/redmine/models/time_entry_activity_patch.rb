module EasyMoney
  module TimeEntryActivityPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :easy_money_rates, :as => :entity, :class_name => 'EasyMoneyRate', :dependent => :destroy

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntryActivity', 'EasyMoney::TimeEntryActivityPatch'
