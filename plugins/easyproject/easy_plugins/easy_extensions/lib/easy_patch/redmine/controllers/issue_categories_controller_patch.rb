module EasyPatch
  module IssueCategoriesControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        helper :issues
        include IssuesHelper
      end
    end

    module InstanceMethods

      def move_category
        direction = params[:issue_category][:move_to]
        category = IssueCategory.find(params[:id])

        ret = nil

        case direction
        when 'highest'
          ret = category.move_to_left_of(category.siblings.first) if category.left_sibling
        when 'higher'
          ret = category.move_left if category.left_sibling
        when 'lower'
          ret = category.move_right if category.right_sibling
        when 'lowest'
          ret = category.move_to_right_of(category.siblings.last) if category.right_sibling
        end

        if ret
          flash[:notice] = l(:text_issue_category_successful_move)
        else
          flash[:error] = l(:text_issue_category_unsuccessful_move)
        end

        redirect_to :controller => 'projects', :action => 'settings', :tab => 'categories', :id => @project
      end

    end

    module ClassMethods
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'IssueCategoriesController', 'EasyPatch::IssueCategoriesControllerPatch'
