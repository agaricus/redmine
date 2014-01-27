#require 'easy_money_migration_from_redmine_cost'

module EasyMoney
  class EasyMoneyMigrationFromRedmineCost

    def self.migrate

      #activate module 'easy_money' to all projects with module 'costs_module'
      Project.all.each do |project|
        if project.module_enabled?(:costs_module)
          project.enabled_module_names = project.enabled_modules.collect(&:name) + ['easy_money']
        end
      end

      redmine_rates = Setting.plugin_redmine_costs

      redmine_rates['costs_roles'].each do |key, value|
        EasyMoneyRateType.all.each do |rate_type|
          EasyMoneyRate.create(:rate_type_id => rate_type.id, :entity_type => 'Role', :entity_id => key, :unit_rate => value)
        end
      end

      redmine_rates['costs_activities'].each do |key, value|
        EasyMoneyRateType.all.each do |rate_type|
          EasyMoneyRate.create(:rate_type_id => rate_type.id, :entity_type => 'Enumeration', :entity_id => key, :unit_rate => value)
        end
      end

      Costable.all.each do |costable|
        EasyMoneyRateType.all.each do |rate_type|
          if costable.costable_type == 'Role'
            entity_type = 'Role'
          else
            entity_type = 'Enumeration'
          end
          EasyMoneyRate.create(:project_id => costable.project_id, :rate_type_id => rate_type.id, :entity_type => entity_type, :entity_id => costable.costable_id, :unit_rate => costable.cost)
        end
      end

      emoecf = EasyMoneyOtherExpenseCustomField.create(:name => 'Kategorie', :field_format => 'list', :possible_values => OtherCostType.all.collect(&:name))

      OtherCost.all.each do |other_cost|
        if other_cost.issue_id.nil?
          entity_type = 'Project'
        else
          entity_type = 'Issue'
        end
        emoe = EasyMoneyOtherExpense.create(:spent_on => other_cost.spent_on, :name => other_cost.name, :description => other_cost.description, :price1 => other_cost.cost, :entity_type => entity_type, :entity_id => other_cost.project_id)
        unless other_cost.cost_type_id.nil?
          emoe.custom_values.detect{|cv| cv.custom_field_id == emoecf.id}.value = OtherCostType.find(other_cost.cost_type_id).name
          emoe.save
        end
      end

      Project.all.select{|p| p.predicted_cost != 0}.each do |project|
        EasyMoneyOtherRevenue.create(:spent_on => project.created_on, :name => 'Rozpočet', :description => 'Rozpočet', :price1 => project.predicted_cost, :entity_type => 'Project', :entity_id => project.id)
      end

      #disable module 'costs_module' to all projects with this module
      Project.all.each do |project|
        if project.module_enabled?(:costs_module)
          project.enabled_module_names = project.enabled_modules.collect(&:name) - ['costs_module']
        end
      end

    end

  end
end