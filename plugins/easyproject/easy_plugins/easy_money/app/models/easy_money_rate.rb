class EasyMoneyRate < ActiveRecord::Base
  self.table_name = 'easy_money_rates'

  belongs_to :project, :class_name => 'Project', :foreign_key => 'project_id'
  belongs_to :rate_type, :class_name => 'EasyMoneyRateType', :foreign_key => 'rate_type_id'
  belongs_to :entity, :polymorphic => true

  scope :easy_money_rate_by_project_by_rate_by_entity, lambda {|project, rate, entity_type, entity_id| where("#{EasyMoneyRate.table_name}.project_id = #{project.id} AND #{EasyMoneyRate.table_name}.rate_type_id = #{rate.id} AND #{EasyMoneyRate.table_name}.entity_type = '#{entity_type}' AND #{EasyMoneyRate.table_name}.entity_id = #{entity_id}") }

  # Return the EasyMoneyRate record based on params
  def self.get_rate(rate_type, entity_type, entity_id, project_id = nil, valid_from = nil, valid_to = nil)
    scope = get_rate_scope(rate_type, entity_type, entity_id, project_id, valid_from, valid_to)
    scope.first if scope
  end

  # Return the EasyMoneyRate scope based on params
  def self.get_rate_scope(rate_type, entity_type, entity_id, project_id = nil, valid_from = nil, valid_to = nil)
    return nil if entity_type.blank? || entity_id.blank?

    rate_type_id = rate_type.is_a?(EasyMoneyRateType) ? rate_type.id : rate_type.to_i

    scope = EasyMoneyRate.where(["#{EasyMoneyRate.table_name}.rate_type_id = ?", rate_type_id])
    scope = scope.where(["#{EasyMoneyRate.table_name}.entity_type = ?", entity_type])
    scope = scope.where(["#{EasyMoneyRate.table_name}.entity_id = ?", entity_id])

    if project_id.nil?
      scope = scope.where("#{EasyMoneyRate.table_name}.project_id IS NULL")
    else
      scope = scope.where(["#{EasyMoneyRate.table_name}.project_id = ?", project_id])
    end
    #    cond << ["#{EasyMoneyRate.table_name}.valid_from <= ? OR #{EasyMoneyRate.table_name}.valid_from IS NULL", valid_from.to_date] unless valid_from.nil?
    #    cond << ["#{EasyMoneyRate.table_name}.valid_to >= ? OR #{EasyMoneyRate.table_name}.valid_to IS NULL", valid_to.to_date] unless valid_to.nil?

    scope
  end

  # Return unit_rate field from the EasyMoneyRate record
  def self.get_unit_rate(rate_type, entity_type, entity_id, project_id = nil, valid_from = nil, valid_to = nil)
    scope = get_rate_scope(rate_type, entity_type, entity_id, project_id, valid_from, valid_to)
    unit_rate = scope.pluck(:unit_rate).first if scope

    if unit_rate.nil? && !project_id.blank?
      scope = get_rate_scope(rate_type, entity_type, entity_id, nil, valid_from, valid_to)
      unit_rate = scope.pluck(:unit_rate).first if scope
    end

    unit_rate || 0.0
  end

  def self.copy_to(project_from, project_to)
    EasyMoneyRate.where(:project_id => project_from.id).all.each do |project_from_rate|
      rate = project_from_rate.dup
      rate.project_id = project_to.id
      rate.save
    end
  end

  def self.get_easy_money_rate_by_project(project, fallback_to_global = true)
    project_id = project.is_a?(Project) ? project.id : project

    emr = EasyMoneyRate.where(["#{EasyMoneyRate.table_name}.project_id = ?", project_id]).all
    emr = EasyMoneyRate.where("#{EasyMoneyRate.table_name}.project_id IS NULL").all if emr.blank? && fallback_to_global
    emr
  end

  def self.get_easy_money_rate_by_project_and_entity_type(project, entity_type, fallback_to_global = true)
    project_id = project.is_a?(Project) ? project.id : project

    emr = EasyMoneyRate.where(["#{EasyMoneyRate.table_name}.project_id = ?", project_id]).where(["#{EasyMoneyRate.table_name}.entity_type = ?", entity_type]).all
    emr = EasyMoneyRate.where("#{EasyMoneyRate.table_name}.project_id IS NULL").where(["#{EasyMoneyRate.table_name}.entity_type = ?", entity_type]).all if emr.blank? && fallback_to_global
    emr
  end

  # Return a concrete unit_rate based on rate priorities for a time entry
  def self.get_unit_rate_for_time_entry(time_entry, rate_type)
    get_unit_rate_for_entity(time_entry, rate_type, time_entry.project_id, time_entry.spent_on, time_entry.spent_on)
  end

  # Return a concrete unit_rate based on rate priorities for a issue
  def self.get_unit_rate_for_issue(issue, rate_type)
    get_unit_rate_for_entity(issue, rate_type, issue.project_id, nil, nil)
  end

  def self.get_unit_rate_for_entity(entity, rate_type, project_id = nil, valid_from = nil, valid_to = nil)
    rate_type_id = rate_type.is_a?(EasyMoneyRateType) ? rate_type.id : rate_type.to_i
    return 0.0 if rate_type_id <= 0

    unit_rate = 0.0

    EasyMoneyRatePriority.rate_priorities_by_rate_type_and_project(rate_type_id, project_id).pluck(:entity_type).each do |rate_priority_entity_type|
      break if unit_rate > 0.0

      entity_type = case rate_priority_entity_type
      when 'TimeEntryActivity'
        'Enumeration'
      when 'User'
        'Principal'
      else
        'Role'
      end

      entity_id = get_easy_money_rate_entity_id_for_entity(entity, rate_priority_entity_type)
      next if entity_id.nil?

      unit_rate = EasyMoneyRate.get_unit_rate(rate_type, entity_type, entity_id, project_id, valid_from, valid_to)
    end

    unit_rate
  end

  def self.get_easy_money_rate_entity_id_for_entity(entity, easy_money_rate_entity_type)
    case entity.class.name
    when 'TimeEntry'
      get_easy_money_rate_entity_id_for_time_entry(entity, easy_money_rate_entity_type)
    when 'Issue'
      get_easy_money_rate_entity_id_for_issue(entity, easy_money_rate_entity_type)
    else
      nil
    end
  end

  def self.get_easy_money_rate_entity_id_for_time_entry(time_entry, easy_money_rate_entity_type)
    case easy_money_rate_entity_type
    when 'Role'
      role = time_entry.user.roles_for_project(time_entry.project).sort_by(&:position).first
      role && role.id
    when 'TimeEntryActivity'
      time_entry.activity_id
    when 'User'
      time_entry.user_id
    end
  end

  def self.get_easy_money_rate_entity_id_for_issue(issue, easy_money_rate_entity_type)
    case easy_money_rate_entity_type
    when 'Role'
      role = issue.assigned_to.roles_for_project(issue.project).sort_by(&:position).first if issue.assigned_to
      role && role.id
    when 'TimeEntryActivity'
      issue.activity_id
    when 'User'
      issue.assigned_to_id
    end
  end

end
