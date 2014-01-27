module EasyMoney
  module ProjectMassCopyControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def copy_easy_money_rate_priorities
          return true unless @source_project.module_enabled?('easy_money')
          @target_projects.each do |target_project|
            next unless target_project.module_enabled?('easy_money')

            EasyMoneyRatePriority.rate_priorities_by_project(target_project).each(&:destroy)
            EasyMoneyRatePriority.rate_priorities_by_project(@source_project).copy_to(target_project)
          end

          true
        end

        def copy_easy_money_rates
          return true unless @source_project.module_enabled?('easy_money')
          @target_projects.each do |target_project|
            next unless target_project.module_enabled?('easy_money')

            EasyMoneyRate.get_easy_money_rate_by_project(target_project, false).each(&:destroy)
            EasyMoneyRate.copy_to(@source_project, target_project)
          end

          true
        end

        def copy_easy_money_settings
          return true unless @source_project.module_enabled?('easy_money')
          @target_projects.each do |target_project|
            next unless target_project.module_enabled?('easy_money')

            EasyMoneySettings.find(:all, :conditions => {:project_id => target_project.id}).each(&:destroy)
            EasyMoneySettings.copy_to(@source_project, target_project)
          end

          true
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ProjectMassCopyController', 'EasyMoney::ProjectMassCopyControllerPatch'
