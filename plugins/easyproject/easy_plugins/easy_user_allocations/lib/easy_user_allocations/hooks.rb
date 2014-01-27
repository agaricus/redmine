module EasyUserAllocations
  class Hooks < Redmine::Hook::ViewListener

    render_on(:view_quick_project_planner_bottom, :partial => 'easy_quick_project_planner/allocation_link')

    def model_project_after_day_shifting(context={})
      project = context[:project]

      return unless project

      project.issues.all_to_allocate.allocate!
    end

  end
end
