module EasyUserAllocationGanttHelper

  def allocation_issues_data(api, user_timeline, period, visible_ids=nil)
    api.array :entities do
      entities = user_timeline.keys.select{|i| visible_ids.nil? || visible_ids.include?(i.id)}
      if @query && @query.grouped? && @query.group_by_column.name == :project
        entities = entities.group_by(&:project)
      else
        entities = entities.group_by{|i| nil}
      end
      entities.each do |key, issues|
        allocation_project_data(api, key) if key.is_a?(Project)
        issues.each do |i|
          data = user_timeline[i]
          p = key || i.project
          api.entity do
            api.type 'issue'
            start = EasyUserAllocation.keep_issue_start_dates? && i.start_date ? [i.start_date, data.first.date].min : data.first.date
            if data.present? && start && ((i.start_date && period[:from] > i.start_date) && (start <= period[:from]) || (i.due_date && period[:to] < i.due_date))
              if i.estimated_hours && data.sum(&:hours) < i.estimated_hours - i.spent_hours
                api.readonly true
                api.wormtitle l(:label_allocation_worm_out_of_range)
              else
                if i.start_date < period[:from]
                  issue_start_out_of_range = true
                  start = period[:from]
                end
              end
            end
            api.id i.id
            api.css_classes i.css_classes
            api.href issue_path(i)
            api.project_id p.id
            api.project p.name
            api.status i.status.name
            api.is_planned p.is_planned
            api.projecthref project_path(p)
            api.est((100*(i.estimated_hours || 0)).round.to_f/100)
            api.activity i.activity.name if i.activity
            spent_hours = i.spent_hours || 0.0
            if spent_hours > 0
              api.spenttime((100*i.spent_hours).round.to_f/100)
              api.hoursleft((100*(i.estimated_hours - i.spent_hours)).round.to_f/100) if i.estimated_hours
            end
            api.name i.subject
            api.start start.to_s
            api.end i.due_date.to_s if i.due_date
            api.originalstart i.start_date
            api.startdate i.start_date
            api.duedate i.due_date
            api.percentcompleted i.done_ratio if i.done_ratio
            api.author i.author.name
            call_hook :view_user_allocation_gantt_data_issue, :api => api, :issue => i
            api.array :allocations do
              if EasyUserAllocation.keep_issue_start_dates? && i.start_date_was && data.first.date > i.start_date
                ((issue_start_out_of_range ? period[:from] : i.start_date)..(data.first.date - 1.day)).each do
                  api.allocation do
                    api.hours 0
                    api.custom false
                  end
                end
              end
              data.each do |allocation|
                api.allocation do
                  api.hours((100*allocation.hours).round.to_f/100)
                  api.custom allocation.custom
                end
              end
            end
          end
        end
      end
    end
  end

  def allocation_project_data(api, project)
    api.entity do
      api.type 'project'
      api.id   project.id
      api.name project.name
      api.href project_path(project)
    end
  end

  def easy_user_allocation_tabs
    tabs = [
      {:name => 'gantt', :label => :label_user_allocation_gantt, :redirect_link => true, :url => {:controller => 'user_allocation_gantt'}},
      {:name => 'allocations_by_project', :label => :label_allocations_by_project, :redirect_link => true, :url => {:controller => 'user_allocation_gantt', :action => 'by_project'}}
    ]
    tabs << {:name => 'working_plan', :label => :label_user_allocation_plan, :redirect_link => true, :url => {:controller => 'user_allocation_plan'}} if EasyUserAllocationWorkingPlanItem.is_enabled

    tabs
  end

  def resalloc_filter_options(query)
    opts = {'' => [['', '']] + query.basic_filters.sort{|a,b| a[1][:order] <=> b[1][:order]}.collect{|field| [field[1][:name], field[0]] unless query.has_filter?(field[0])}.compact}

    if query.is_a?(EasyUserAllocationByProjectQuery)
      opts[l(:label_project_plural)] = query.project_filters.sort{|a,b| a[1][:order] <=> b[1][:order]}.collect{|field| [field[1][:name], field[0]] unless query.has_filter?(field[0])}.compact
    else
      opts[l(:label_issue_plural)] = query.issue_filters.sort{|a,b| a[1][:order]<=>b[1][:order]}.collect{|field| [ field[1][:name], field[0]] unless query.has_filter?(field[0])}.compact
    end

    opts[l(:label_user_plural)] = query.user_filters.sort{|a,b| a[1][:order]<=>b[1][:order]}.collect{|field| [ field[1][:name], field[0]] unless query.has_filter?(field[0])}.compact

    grouped_options_for_select(opts)
  end

end
