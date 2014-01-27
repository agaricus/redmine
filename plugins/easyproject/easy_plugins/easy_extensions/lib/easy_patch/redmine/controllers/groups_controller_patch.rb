module EasyPatch
  module GroupsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :add_users, :easy_extensions
        alias_method_chain :edit_membership, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions

      end
    end

    module InstanceMethods

      def add_users_with_easy_extensions
        @users = User.find_all_by_id(params[:user_id] || params[:user_ids])
        @users.reject!{|u| @group.users.include?(u)}
        @group.users << @users if request.post? && !@users.blank?
        respond_to do |format|
          format.html { redirect_to edit_group_path(@group, :tab => 'users') }
          format.js
          format.api { render_api_ok }
        end
      end

      def edit_membership_with_easy_extensions
        if params[:membership]
          project_ids = params[:membership].delete(:project_ids) || []

          project_ids.each do |project_id|
            next if project_id.blank?
            unless Member.where(:user_id => params[:membership][:user_id], :project_id => project_id).exists?
              @membership = Member.edit_membership(params[:membership_id], params[:membership], @group)
              @membership.project_id = project_id
              @membership.save if request.post?
            end
          end
        end
        @membership ||= Member.edit_membership(params[:membership_id], params[:membership], @group)
        respond_to do |format|
          format.html { redirect_to edit_group_path(@group, :tab => 'memberships') }
          format.js
        end
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:groups)
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'GroupsController', 'EasyPatch::GroupsControllerPatch'
