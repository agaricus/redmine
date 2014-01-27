module EasyPatch
  module MembersControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :edit_project_activity_roles, :only => [:edit]
        before_filter :create_project_activity_roles, :only => [:new, :edit]
        after_filter :delete_project_activity_roles, :only => [:destroy]
        
        private
        
        def edit_project_activity_roles
          if params[:member] && request.post?
            # current roles -  ids from form => if user remove role this role is destroy from par here only if role have only 1 member.
            (@member.role_ids - params[:member][:role_ids].collect(&:to_i)).each do |role_id_to_delete|
              ProjectActivityRole.delete_all(:project_id => @project.id, :role_id => role_id_to_delete) if Role.find(role_id_to_delete).members.count(:all, :conditions => {:project_id => @project.id}) == 1
            end
          end
        end
        
        def create_project_activity_roles
          if params[:member] && request.post?
            role_ids = @project.all_members_roles.collect{|i| i.id.to_s}
            (params[:member][:role_ids] - role_ids).each do |role_id|
              @project.activities.each do |activity|
                ProjectActivityRole.create(:project_id => @project.id, :activity_id => activity.id, :role_id => role_id) if ProjectActivityRole.count(:conditions => {:project_id => @project.id, :activity_id => activity.id, :role_id => role_id}) == 0
              end
            end if params[:member][:role_ids].present?
          end
        end
        
        def delete_project_activity_roles
          # actual project roles
          pmr = @project.all_members_roles.pluck(:id).uniq
          par = @project.project_activity_roles.pluck(:role_id).uniq
          (par - pmr).each do |role_id|
            ProjectActivityRole.delete_all(:project_id => @project.id, :role_id => role_id)
          end
        end
  
      end

    end

    module InstanceMethods

    end
    
  end
end
EasyExtensions::PatchManager.register_controller_patch 'MembersController', 'EasyPatch::MembersControllerPatch'
