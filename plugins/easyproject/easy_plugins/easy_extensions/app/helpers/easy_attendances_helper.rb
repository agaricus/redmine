module EasyAttendancesHelper

  def easy_attendance_query_additional_ending_buttons(entity, options = {})
    s = ''

    if entity.can_edit?
      s << link_to(l(:button_edit), {:controller => 'easy_attendances', :action => 'edit', :id => entity, :tab => params[:tab], :back_url => url_for(:controller => controller_name , :action => action_name, :tab => params[:tab])}, :class => 'icon icon-edit')
      s << link_to(l(:button_delete), {:controller => 'easy_attendances', :action => 'destroy', :id => entity,:tab => params[:tab], :back_url => url_for(:controller => controller_name , :action => action_name, :tab => params[:tab])}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
    end
    s.html_safe
  end

  def easy_attandance_tabs
    tabs = [
      {:name => 'calendar', :partial => 'calendar', :label => :label_calendar, :redirect_link => true, :url => easy_attendances_path(:tab => 'calendar')},
      {:name => 'list', :partial => 'index', :label => :label_list, :redirect_link => true, :url => easy_attendances_path(:tab => 'list')},
      {:name => 'report', :partial => 'report', :label => :label_report, :redirect_link => true, :url => url_for({:controller => 'easy_attendances', :action => 'report', :tab => 'report'})}
    ]
    tabs.delete_at(0) if in_mobile_view?

    return tabs
  end
end
