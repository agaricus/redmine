class EasyTimeEntryBaseQuery < EasyQuery

  def self.permission_view_entities
    :view_time_entries
  end

  def query_after_initialize
    super
    self.sort_criteria = {'0'=>['spent_on', 'asc']} if self.sort_criteria.blank?

    self.display_project_column_if_project_missing = false
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    group = l(:label_filter_group_easy_time_entry_query)

    @available_filters = {
      'spent_on' => {:type => :date_period, :order => 1, :group => group},
      'activity_id' => {:type => :list, :order => 10, :values => Proc.new{TimeEntryActivity.shared.active.collect{|i| [i.name, i.id.to_s]}}, :group => group},
      'tracker_id' => {:type => :list, :order => 11, :values => (project ? Proc.new{project.trackers.collect{|t| [t.name, t.id.to_s]}} : Proc.new{ Tracker.all.collect{|t| [t.name, t.id.to_s]} }), :group => group}
    }

    unless project
      @available_filters['xproject_id'] = { :type => :list_optional, :order => 5, :values => Proc.new{self.projects_for_select}, :group => group, :name => l(:field_project)}
      @available_filters['parent_id'] = { :type => :list, :order => 6, :values => Proc.new{self.projects_for_select}, :group => group}
      @available_filters['project_root_id'] = { :type => :list, :order => 7, :values => Proc.new{self.projects_for_select(Project.visible.roots.select([:id, :name, :easy_level]).all, false)}, :group => group}
    end
    if User.current.allowed_to_globally?(:view_all_statements, {})
      @available_filters['user_id'] = { :type => :list, :order => 15, :values => Proc.new do
          users = User.active.non_system_flag.easy_type_internal.sorted.collect{|i| [i.name, i.id.to_s]}
          users.unshift(["<< #{l(:label_me)} >>", 'me']) if User.current.logged?
          users
        end, :group => group
      }
    end

    @available_filters['user_roles'] = { :type => :list, :order => 9, :values => Proc.new{Role.givable.collect {|r| [r.name, r.id.to_s]}}, :group => group}

    add_custom_fields_filters(TimeEntryCustomField)

    add_associations_custom_fields_filters :project

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:spent_on, :sortable => "#{TimeEntry.table_name}.spent_on", :groupable => true),
        EasyQueryColumn.new(:user, :groupable => true, :sortable => ["#{User.table_name}.lastname", "#{User.table_name}.firstname", "#{User.table_name}.id"]),
        EasyQueryColumn.new(:activity, :groupable => true, :sortable => "#{TimeEntryActivity.table_name}.name"),
        EasyQueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :groupable => true),
        EasyQueryColumn.new(:tracker),
        EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:project_root,
          :sortable => "(SELECT p.id FROM #{Project.table_name} p WHERE p.lft <= #{Project.table_name}.lft AND p.rgt >= #{Project.table_name}.rgt AND p.parent_id IS NULL)",
          :sumable_sql => "(SELECT p.id FROM #{Project.table_name} p WHERE p.lft <= #{Project.table_name}.lft AND p.rgt >= #{Project.table_name}.rgt AND p.parent_id IS NULL)",
          :groupable => true),
        # :sumable_sql => "(SELECT r.role_id FROM member_roles r INNER JOIN members m ON m.id = r.member_id WHERE m.project_id = #{TimeEntry.table_name}.project_id AND m.user_id = #{TimeEntry.table_name}.user_id)"
        EasyQueryColumn.new(:user_roles, :groupable => false),
        EasyQueryColumn.new(:comments),
        EasyQueryColumn.new(:hours, :sortable => "#{TimeEntry.table_name}.hours", :sumable => :bottom, :caption => 'label_spent_time'),
        EasyQueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours", :sumable => :bottom, :sumable_sql => "(SELECT i.estimated_hours FROM #{Issue.table_name} i WHERE i.id = #{TimeEntry.table_name}.issue_id)", :sumable_options=>{:distinct_columns => [["#{Issue.table_name}.id", :issue]]}),
        EasyQueryColumn.new(:easy_range_from),
        EasyQueryColumn.new(:easy_range_to),
        EasyQueryColumn.new(:created_on),
        EasyQueryColumn.new(:updated_on)
      ]
      @available_columns << EasyQueryColumn.new(:issue_id, :sortable => "#{Issue.table_name}.id") if EasySetting.value('show_issue_id', project)
      @available_columns += TimeEntryCustomField.visible.all.collect {|cf| EasyQueryCustomFieldColumn.new(cf)}
      @available_columns += ProjectCustomField.visible.all.collect{|cf| EasyQueryCustomFieldColumn.new(cf, :assoc => :project)}
      @available_columns_added = true
    end
    @available_columns
  end

  def columns_with_me
    super + ['user_id']
  end

  def entity
    TimeEntry
  end

  def entity_scope
    TimeEntry.non_templates.visible
  end

  def default_find_include
    [:project, :user, :issue, :activity]
  end

  def default_sort_criteria
    ['spent_on']
  end

  def get_custom_sql_for_field(field, operator, value)
    case field
    when 'activity_id'
      db_table = TimeEntry.table_name
      db_field = 'activity_id'
      sql = "#{db_table}.activity_id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{TimeEntryActivity.table_name}.id FROM #{TimeEntryActivity.table_name} WHERE #{TimeEntryActivity.table_name}.parent_id = '#{value}' OR "
      sql << sql_for_field(field, '=', value, db_table, db_field) + ')'
      return sql
    when'user_roles'
      v = value.is_a?(Array) ? value.join(',') : value
      o = (operator == '=') ? 'IN' : 'NOT IN'
      sql = "EXISTS (SELECT r.id FROM member_roles r INNER JOIN members m ON m.id = r.member_id WHERE m.user_id = #{User.table_name}.id AND m.project_id = #{TimeEntry.table_name}.project_id AND r.role_id #{o} (#{v}))"
      return sql
    when 'project_root_id'
      db_table = TimeEntry.table_name
      db_field = 'project_id'
      v = "SELECT #{Project.table_name}.id FROM #{Project.table_name} WHERE "
      if value.is_a?(Array)
        projects = Project.find(value)
        v << projects.collect{|p| Project.allowed_to_condition(User.current, :view_all_statements, {:project => p, :with_subprojects => Setting.display_subprojects_issues?})}.join(' OR ')
      else
        v << Project.visible.allowed_to_condition(User.current, :log_time, {:project => Project.find(value), :with_subprojects => Setting.display_subprojects_issues?})
      end
      o = (operator == '=') ? 'IN' : 'NOT IN'
      sql = "#{db_table}.#{db_field} #{ operator == '=' ? 'IN' : 'NOT IN' } (#{v})"
      return sql
    when 'parent_id'
      op_not = (operator_for('parent_id') == '!')

      return "#{Project.table_name}.id #{op_not ? 'NOT IN' : 'IN'} (SELECT p_parent_id.id FROM #{Project.table_name} p_parent_id WHERE p_parent_id.parent_id IN (#{values_for('parent_id').join(',')}))"

    end
  end

  def sql_for_xproject_id_field(field, operator, v)
    db_table = self.entity.table_name
    db_field = 'project_id'
    returned_sql_for_field = self.sql_for_field(db_field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

  def sql_for_tracker_id_field(field, operator, v)
    db_table = Issue.table_name
    db_field = field
    returned_sql_for_field = self.sql_for_field(field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

  def sql_for_activity_id_field(field, operator, value)
    condition_on_id = sql_for_field(field, operator, value, Enumeration.table_name, 'id')
    condition_on_parent_id = sql_for_field(field, operator, value, Enumeration.table_name, 'parent_id')
    ids = value.map(&:to_i).join(',')
    table_name = Enumeration.table_name
    if operator == '='
      "(#{table_name}.id IN (#{ids}) OR #{table_name}.parent_id IN (#{ids}))"
    else
      "(#{table_name}.id NOT IN (#{ids}) AND (#{table_name}.parent_id IS NULL OR #{table_name}.parent_id NOT IN (#{ids})))"
    end
  end

end
