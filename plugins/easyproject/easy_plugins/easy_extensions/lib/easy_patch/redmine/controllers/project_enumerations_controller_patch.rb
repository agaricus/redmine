module EasyPatch

  module ProjectEnumerationsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        
        include EasySettingHelper
        
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :update, :easy_extensions

        private

        def update_easy_settings
          save_easy_settings(@project)
          if @project && (@project.fixed_activity? == EasySetting.value('project_fixed_activity'))
            EasySetting.delete_key('project_fixed_acitvity', @project)
          end
        end
                
        def update_project_acitvity_roles
          if params[:enumerations] && params[:project_activity_roles]
            ProjectActivityRole.delete_all(:project_id => @project.id)
            @project.reload
            @project.activities.each do |activity|
              activity_roles = params[:project_activity_roles][activity.id.to_s]
              activity_roles && activity_roles.each do |role_id| # realy exist activity roles?
                add_new_project_activity_role(activity.parent_id || activity.id, role_id)
              end
            end
          end
        end
                
        def add_new_project_activity_role(activity_id, role_id)
          @project.project_activity_roles << ProjectActivityRole.new(:activity_id => activity_id, :role_id => role_id)
        end

      end
    end
    
    module InstanceMethods
      
      def update_with_easy_extensions
        if request.put?
          update_easy_settings
          @project.project_time_entry_activities.clear
          if params[:enumerations]
            
            params[:enumerations].each do |id, activity|
              @project.project_time_entry_activities << TimeEntryActivity.find(id) if activity['active'] == '1'
            end

            update_project_acitvity_roles

            flash[:notice] = l(:notice_successful_update)
          end
        end

        redirect_to settings_project_path(@project, :tab => 'activities')
      end

      def destroy_with_easy_extensions
        # nothing to do
        redirect_to settings_project_path(@project, :tab => 'activities')
      end

    end
    
  end
end
EasyExtensions::PatchManager.register_controller_patch 'ProjectEnumerationsController', 'EasyPatch::ProjectEnumerationsControllerPatch'
