module EasyRedmine
  class Hooks < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context={})
      stylesheet_link_tag('easy_redmine', :plugin => 'easy_redmine')
    end

  end
end