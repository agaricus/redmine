class EasyUserAllocationObserver < ActiveRecord::Observer
  observe :issue, :time_entry

  def after_update(entity)
    allocate_entity(entity)
  end

  def after_create(entity)
    allocate_entity(entity)
  end

  def allocate_entity(entity)
    issue = entity if entity.is_a?(Issue)
    issue = entity.issue if entity.is_a?(TimeEntry)

    if issue && !issue.project.easy_is_easy_template?
      custom_allocations = issue.easy_user_allocations.where(:custom => true).all.reduce({}) {|h, alloc| h[alloc.date] = alloc.hours; h}
      EasyUserAllocation.allocate_issue!(issue, nil, custom_allocations)
    end
  end

end
