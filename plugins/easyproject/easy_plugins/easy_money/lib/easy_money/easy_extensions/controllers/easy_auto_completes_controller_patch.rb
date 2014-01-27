module EasyMoney
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def easy_money_projects
          @projects = get_visible_easy_money_projects(params[:term], params[:term].blank? ? nil : 15)

          respond_to do |format|
            format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
          end
        end

        def get_visible_easy_money_projects(term='', limit=nil)
          scope = get_visible_projects_scope(term, limit)
          scope = scope.has_module(:easy_money)
          scope.all
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyMoney::EasyAutoCompletesControllerPatch'
