module EasyAgileBoard
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_projects_show_bottom, :partial => 'easy_agile_board/project_button'

    def view_layouts_base_html_head(context={})
      stylesheet_link_tag 'easyagile', :plugin => 'easy_agile_board'
    end

  end
end
