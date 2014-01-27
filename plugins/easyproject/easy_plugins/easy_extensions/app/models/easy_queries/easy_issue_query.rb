class EasyIssueQuery < EasyQuery

  def self.entity_css_classes(issue, options={})
    user = options[:user] || User.current
    level = options[:level]
    issue.css_classes(user, level)
  end

  def self.permission_view_entities
    :view_issues
  end

  def query_after_initialize
    super
    self.export_formats[:atom] = {:url => {:key => User.current.rss_key}}
    self.export_formats[:ics] = {:caption => 'iCal', :url => {:protocol => 'webcal', :key => User.current.api_key, :only_path => false}, :title => l(:title_other_formats_links_ics_outlook)}
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = project_statement unless project_statement.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    principals = []
    group = l("label_filter_group_#{self.class.name.underscore}")
    @available_filters = {}
    @available_filters['status_id'] = { :type => :list_status, :order => 3, :values => Proc.new{IssueStatus.reorder(:position).all.collect{|s| [s.name, s.id.to_s]}} , :group => group, :includes => [:status]}
    @available_filters['tracker_id'] = { :type => :list, :order => 4, :values => Proc.new{self.trackers.collect{|s| [s.name, s.id.to_s]}} , :group => group, :includes => [:tracker]}
    @available_filters['priority_id'] = { :type => :list, :order => 5, :values => Proc.new{IssuePriority.active.all.collect{|s| [s.name, s.id.to_s]}} , :group => group, :includes => [:priority]}
    @available_filters['subject'] = { :type => :string, :order => 12 , :group => group}
    @available_filters['start_date'] = { :type => :date_period, :time_column => false, :order => 13 , :group => group}
    @available_filters['due_date'] = { :type => :date_period, :time_column => false, :order => 14 , :group => group}
    @available_filters['created_on'] = { :type => :date_period, :time_column => true, :order => 15 , :group => group}
    @available_filters['updated_on'] = { :type => :date_period, :time_column => true, :order => 16 , :group => group}
    @available_filters['not_updated_on'] = { :type => :date_period, :time_column => true, :order => 17, :label => :label_not_updated_on, :group => group}
    @available_filters['estimated_hours'] = { :type => :float, :order => 18 , :group => group}

    if project ? User.current.allowed_to?(:view_time_entries, project) : User.current.allowed_to_globally?(:view_time_entries, {})
      @available_filters['sum_of_timeentries'] = { :type => :float, :order => 19 , :group => group}
      @available_filters['spent_estimated_timeentries'] = { :type => :integer, :order => 20 , :group => group}
    end

    @available_filters['done_ratio'] = { :type => :integer, :order => 21 , :group => group}
    @available_filters['watcher_id'] = { :type => :list, :order => 22, :group => group, :values => Proc.new do
        watcher_values = []
        watcher_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
        watcher_values += User.active.collect{|u| [u.name, u.id.to_s]}.sort
        watcher_values
      end, :includes => [:watchers]
    }
    @available_filters['']
    if EasySetting.value('allow_repeating_issues')
      @available_filters['easy_is_repeating'] = {:type => :list, :order => 25, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']],:group => group}
    end

    IssueRelation::TYPES.each do |relation_type, options|
      @available_filters[relation_type] = {
        :type => :relation, :order => @available_filters.size + 100,
        :label => options[:name],
        :group => l(:label_filter_group_relations)
      }
    end

    if self.project
      principals += self.project.principals.sort
    else
      # members of visible projects
      principals += Principal.active.sorted#.find(:all, :conditions => ["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", all_projects.collect(&:id)]).sort
      @available_filters['project_id'] = {:type => :list_optional, :order => 1, :values => Proc.new do
          project_values = []
          if User.current.logged?
            project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
          end
          project_values += self.all_projects_values
          project_values
        end,
        :group => group,
        :includes => [:project]
      }
      @available_filters['is_planned'] = {:type => :list, :order => 22, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], :group => group}
    end

    users = principals.select {|p| p.is_a?(User)}

    @available_filters['assigned_to_id'] = { :type => :list_optional, :order => 6, :values => Proc.new do
        assigned_to_values = []
        assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
        assigned_to_values += (Setting.issue_group_assignment? ? principals : users).collect{|s| [s.name, s.id.to_s] } unless User.current.external_client?
        assigned_to_values
      end,
      :group => group, :includes => [:assigned_to]
    }

    @available_filters['author_id'] = { :type => :list, :order => 7, :values => Proc.new do
        author_values = []
        author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
        author_values += users.collect{|s| [s.name, s.id.to_s] } unless User.current.external_client?
        author_values
      end,
      :group => group#, :includes => [:author]
    }

    @available_filters['member_of_group'] = { :type => :list_optional, :order => 8, :values => Proc.new do
        Group.all.collect {|g| [g.name, g.id.to_s] }
      end,
      :group => group
    }

    @available_filters['assigned_to_role'] = { :type => :list_optional, :order => 9, :values => Proc.new do
        Role.givable.collect {|r| [r.name, r.id.to_s] }
      end,
      :group => group
    }

    @available_filters['participant_id'] = { :type => :list, :order => 23, :values => Proc.new do
        participant_values = []
        participant_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
        participant_values += users.collect{|s| [s.name, s.id.to_s] }
        participant_values
      end,
      :group => group
    }

    @available_filters['updated_by_who'] = { :type => :list, :order => 23, :values => Proc.new do
        participant_values = []
        participant_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
        participant_values += users.collect{|s| [s.name, s.id.to_s] }
        participant_values
      end,
      :group => group
    }

    if self.project
      @available_filters['category_id'] = { :type => :list_optional, :order => 10, :values => Proc.new do
          result = []
          IssueCategory.each_with_level(self.project.issue_categories.all) do |category, level|
            next if category.nil? || category.id.nil?

            name_prefix = (level > 0 ? '|&nbsp;&nbsp;' * level + '&#8627; ' : '')
            if name_prefix.length > 0
              name_prefix = name_prefix.slice(1, name_prefix.length)
            end

            result << ["#{name_prefix}#{category}".html_safe, category.id.to_s]
          end
          result
        end,
        :group => group
      }

      @available_filters['fixed_version_id'] = { :type => :list_optional, :order => 11, :values => Proc.new do
          project.shared_versions.all.sort.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s]}
        end,
        :group => group, :includes => [:fixed_version]
      }

      unless project.leaf?
        @available_filters['subproject_id'] = { :type => :list_subprojects, :order => 2, :values => Proc.new do
            subprojects = project.easy_is_easy_template? ? project.descendants.visible.templates.select([:id, :name, :easy_level]).all : project.descendants.visible.non_templates.select([:id, :name, :easy_level]).all
            subprojects.collect{|s| [s.name, s.id.to_s]}
          end,
          :group => l(:label_filter_group_project_fields)
        }
      end

      add_custom_fields_filters(project.all_issue_custom_fields)
    else
      # global filters for cross project issue list
      @available_filters['fixed_version_id'] = { :type => :list_optional, :order => 11, :values => Proc.new do
          system_shared_versions = Version.visible.where(:projects => {:easy_is_easy_template => false}).includes(:project).all
          system_shared_versions.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s]}.sort
        end,
        :group => group
      }

      add_custom_fields_filters(IssueCustomField.where(:is_for_all => true))
    end

    add_associations_custom_fields_filters :project, :author, :assigned_to, :fixed_version

    if User.current.allowed_to?(:set_issues_private, nil, :global => true) ||
        User.current.allowed_to?(:set_own_issues_private, nil, :global => true)
      @available_filters['is_private'] = { :type => :list, :order => 15, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], :group => group }
    end

    Tracker.disabled_core_fields(trackers).each {|field|
      @available_filters.delete field
    }

    @available_filters.each do |field, options|
      options[:name] ||= l(options[:label] || "field_#{field}".gsub(/_id$/, ''))
      options[:group] ||= l(:label_filter_group_unknown)
    end

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true, :includes => [:project]),
        EasyQueryColumn.new(:parent_project, :sortable => "#{Project.table_name}.name", :groupable => true, :includes => [:project]),
        EasyQueryColumn.new(:main_project, :sortable => "#{Project.table_name}.name", :groupable => true, :includes => [:project]),
        EasyQueryColumn.new(:parent, :sortable => ["#{Issue.table_name}.root_id", "#{Issue.table_name}.lft"], :default_order => 'desc', :caption => :field_parent_issue),
        EasyQueryColumn.new(:status, :sortable => "#{IssueStatus.table_name}.position", :groupable => true, :includes => [:status]),
        EasyQueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :groupable => true, :includes => [:tracker]),
        EasyQueryColumn.new(:priority, :sortable => "#{IssuePriority.table_name}.position", :default_order => 'desc', :groupable => true, :includes => [:priority]),
        EasyQueryColumn.new(:assigned_to, :sortable => lambda{User.fields_for_order_statement}, :groupable => true, :includes => [:assigned_to]),
        EasyQueryColumn.new(:author, :groupable => "#{Issue.table_name}.author_id", :sortable => lambda{User.fields_for_order_statement('authors')} ),# , :includes => [:author]),
        EasyQueryColumn.new(:fixed_version, :sortable => lambda{Version.fields_for_order_statement}, :groupable => true, :includes => [:fixed_version]),
        EasyQueryColumn.new(:subject, :sortable => "#{Issue.table_name}.subject"),
        EasyQueryColumn.new(:start_date, :sortable => "#{Issue.table_name}.start_date"),
        EasyQueryColumn.new(:due_date, :sortable => "#{Issue.table_name}.due_date"),
        EasyQueryColumn.new(:created_on, :sortable => "#{Issue.table_name}.created_on", :default_order => 'desc'),
        EasyQueryColumn.new(:updated_on, :sortable => "#{Issue.table_name}.updated_on", :default_order => 'desc'),
        EasyQueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours", :sumable => :bottom)
      ]

      if project ? User.current.allowed_to?(:view_time_entries, project) : User.current.allowed_to_globally?(:view_time_entries, {})
        @available_columns += [
          EasyQueryColumn.new(:sum_of_timeentries, :sumable => :bottom, :sumable_sql => "COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0)"),
          EasyQueryColumn.new(:remaining_timeentries, :sumable => :bottom, :sumable_sql => "COALESCE(#{Issue.table_name}.estimated_hours, 0) - COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0)"),
          EasyQueryColumn.new(:spent_estimated_timeentries)
        ]
      end

      @available_columns += [
        EasyQueryColumn.new(:done_ratio, :sortable => "#{Issue.table_name}.done_ratio", :groupable => true),
        EasyQueryColumn.new(:watchers, :caption => :field_watcher),
        EasyQueryColumn.new(:relations, :caption => :label_related_issues),
        EasyQueryColumn.new(:description, :inline => false)
      ]

      if User.current.allowed_to?(:set_issues_private, nil, :global => true) || User.current.allowed_to?(:set_own_issues_private, nil, :global => true)
        @available_columns << EasyQueryColumn.new(:is_private, :sortable => "#{Issue.table_name}.is_private")
      end
      @available_columns << EasyQueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name", :groupable => true, :includes => [:category]) unless EasyExtensions::EasyProjectSettings.disabled_features[:others].include?('issue_categories')
      @available_columns << EasyQueryColumn.new(:id, :sortable => "#{Issue.table_name}.id") if EasySetting.value('show_issue_id', project)
      @available_columns += IssueCustomField.visible.collect {|cf| EasyQueryCustomFieldColumn.new(cf)}

      disabled_fields = Tracker.disabled_core_fields(trackers).map {|field| field.sub(/_id$/, '')}
      @available_columns.reject! {|column| disabled_fields.include?(column.name.to_s)}

      @available_columns_added = true
    end
    @available_columns
  end

  def project=(project)
    @available_filters = nil # reset cached filters on project change
    super
  end

  def gantt_columns
    columns.select {|c| ![:subject, :description].include?(c.name)}
  end

  def searchable_columns
    ["#{Issue.table_name}.subject"]
  end

  def sortable_columns
    c = super
    c['root_id'] = "#{Issue.table_name}.root_id"
    c['lft'] = "#{Issue.table_name}.lft"
    c
  end

  def entity
    Issue
  end

  def entity_scope
    Issue.visible
  end

  def default_find_include
    [:priority]
  end

  def columns_with_me
    result = super
    result << 'participant_id'
    result << 'updated_by_who'
    result
  end

  def trackers
    @trackers ||= project.nil? ? Tracker.order(:position).all : project.rolled_up_trackers
  end

  def entities(options={})
    issues = super(options)
    if has_column?(:spent_hours)
      Issue.load_visible_spent_hours(issues)
    end
    if has_column?(:relations)
      Issue.load_visible_relations(issues)
    end
    issues
  end

  def issue_count_by_group(options={})
    entity_count_by_group(options)
  end

  def issue_sum_by_group(column, options={})
    entity_sum_by_group(column, options)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def journals(options={})
    scope = Journal.visible.includes([:details, :user, {:issue => [:project, :author, :tracker, :status]}])
    scope = scope.where(self.statement)
    scope = scope.order(options[:order]).limit(options[:limit]).offset(options[:offset])
    scope
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the versions
  # Valid options are :conditions
  def versions(options={})
    scope = Version.visible.includes([:project, {:fixed_issues => [:status, :assigned_to, :tracker, :priority]}])
    scope = scope.where(self.statement)
    scope = scope.where(options[:conditions]) unless options[:conditions].blank?
    scope
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def issues_with_versions(options={})
    result = prepare_result(options)
    return [] if result.keys.empty?

    all_issues = result.values.collect{|v| v[:entities]}.flatten
    subtasks = []
    result.each do |key, data|
      data[:entities].delete_if{|i| i.parent && all_issues.include?(i.parent) && subtasks << i}
    end

    if project && (!grouped? || group_by == 'project')

      if EasySetting.value('gantt_show_all_versions', project)
        versions = project.shared_versions.where('effective_date IS NOT NULL').reorder('effective_date DESC')
      else
        versions = []
        result.each do |key, issues|
          versions << issues[:entities].collect(&:fixed_version)
        end
        versions = versions.flatten.delete_if{|v| v.nil? || v.effective_date.nil?}.uniq.sort{|a, b| b.effective_date <=> a.effective_date}
      end

      result.each do |key, issues|
        if grouped?
          group_versions = versions.select{|v| v.project == key}
        else
          group_versions = versions
        end
        versions -= group_versions

        issues[:entities].each_with_index do |issue, i|
          added_versions_count = 0
          while group_versions.any? && ((!issue.due_date.blank? || !issue.start_date.blank?) && (group_versions.last.effective_date < (issue.due_date || issue.start_date + 1.day)))
            issues[:entities].insert(i + added_versions_count, group_versions.pop)
            added_versions_count += 1
          end
        end
        issues[:entities] += group_versions.reverse
      end

      result[result.keys.last][:entities] += versions.reverse
      if EasySetting.value('gantt_versions_above', project)
        result.each do |key, issues|
          reordered = []
          issues_to_push = []
          issues[:entities].each do |entity|
            if entity.is_a?(Issue)
              issues_to_push << entity
            elsif entity.is_a?(Version)
              reordered << entity
              reordered += issues_to_push
              issues_to_push = []
            end
          end
          reordered += issues_to_push
          issues[:entities] = reordered
        end
      end
    end

    subtasks = subtasks.group_by &:easy_level

    subtasks.keys.sort.each do |level|
      subtasks[level].reverse.each do |subtask|
        v_hash = result.values.detect{|v| v[:entities].include?(subtask.parent)}
        v_hash[:entities].insert(v_hash[:entities].index(subtask.parent) + 1, subtask) if v_hash
      end
    end

    if grouped? && group_by == 'project'
      result.to_a.sort{|a, b| a[0].lft <=> b[0].lft}
    else
      result
    end
  end

  def extended_period_options
    {
      :extended_options => [:to_today, :is_null, :is_not_null],
      :option_limit => {
        :after_due_date => ['due_date'],
        :next_week => ['due_date', 'start_date'],
        :tomorrow => ['due_date', 'start_date'],
        :next_7_days => ['due_date', 'start_date'],
        :next_30_days => ['due_date', 'start_date'],
        :next_90_days => ['due_date', 'start_date'],
        :next_month => ['due_date', 'start_date'],
        :next_year => ['due_date', 'start_date']
      },
      :field_disabled_options => {
        'not_updated_on' => [:is_null, :is_not_null]
      }
    }
  end

  # Ruby 2.0 nebere nějaké následujíci metody
  # protected

  def statement_skip_fields
    ['subproject_id', 'is_planned', 'updated_by_who', 'updated_on']
  end

  def add_statement_sql_before_filters
    statements_for_journals = []
    if has_filter?('updated_by_who')
      statements_for_journals << "#{sql_for_field('updated_by_who', operator_for('updated_by_who'), values_for('updated_by_who'), Journal.table_name, 'user_id', false)}"
    end
    if has_filter?('updated_on')
      statements_for_journals << "#{sql_for_field('updated_on', operator_for('updated_on'), values_for('updated_on'), Journal.table_name, 'created_on', false)}"
    end
    return nil unless statements_for_journals.any?
    statements_for_journals << "#{Journal.table_name}.journalized_id = #{Issue.table_name}.id AND #{Journal.table_name}.journalized_type = 'Issue'"

    sql = "EXISTS ( SELECT #{Journal.table_name}.id "
    sql << "FROM #{Journal.table_name} "
    sql << ' WHERE ' + statements_for_journals.reject{|sql| sql.blank? }.join(' AND ') + ')'
    sql
  end

  def project_statement
    project_clauses = []
    if self.project && !self.project.descendants.active.empty?
      ids = [self.project.id]
      if self.has_filter?('subproject_id')
        case self.operator_for('subproject_id')
        when '='
          # include the selected subprojects
          if (values = self.values_for('subproject_id').select(&:present?).collect(&:to_i)).present?
            ids = values
          end
        when '!*'
          # main project only
        else
          # all subprojects
          ids += self.project.descendants.pluck(:id)
        end
      elsif Setting.display_subprojects_issues?
        if self.project.easy_is_easy_template
          ids += self.project.descendants.templates.pluck(:id)
        else
          ids += self.project.descendants.non_templates.pluck(:id)
        end
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif self.project
      project_clauses << "#{Project.table_name}.id = %d" % self.project.id
    elsif !self.project
      project_clauses << "#{Project.table_name}.easy_is_easy_template=#{self.connection.quoted_false}"
      if self.has_filter?('is_planned') && self.values_for('is_planned').size == 1
        planned_val = value_for('is_planned').to_s.to_boolean
        planned_val = !planned_val if operator_for('is_planned') == '!='
        project_clauses << "#{Project.table_name}.status #{planned_val ? '=' : '!='} #{Project::STATUS_PLANNED}"
      end
    end
    project_clauses.any? ? project_clauses.join(' AND ') : nil
  end

  def joins_for_order_statement(order_options, return_type = :sql)
    joins = []

    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{Issue.table_name}.author_id"
      end
      joins += super(order_options, :array)
    end

    case return_type
    when :sql
      joins.any? ? joins.join(' ') : nil
    when :array
      joins
    else
      raise ArgumentError, 'return_type has to be either :sql or :array'
    end
  end

  def sql_for_watcher_id_field(field, operator, value)
    db_table = Watcher.table_name
    db_field = 'user_id'
    sql = "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND "
    sql << sql_for_field(field, '=', value, db_table, db_field) + ')'
    return sql
  end

  def sql_for_member_of_group_field(field, operator, value)
    if operator == '*' # Any group
      groups = Group.all
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      groups = Group.all
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.find_all_by_id(value)
    end
    groups ||= []

    members_of_groups = groups.inject([]) {|user_ids, group|
      if group && group.user_ids.present?
        user_ids << group.user_ids
      end
      user_ids.flatten.uniq.compact
    }.sort.collect(&:to_s)

    sql = '(' + sql_for_field('assigned_to_id', operator, members_of_groups, Issue.table_name, 'assigned_to_id', false) + ')'
    return sql
  end

  def sql_for_assigned_to_role_field(field, operator, value)
    if operator == "*" # Any Role
      roles = Role.givable
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*" # No role
      roles = Role.givable
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      roles = Role.givable.find_all_by_id(value)
    end
    roles ||= []
    roles = roles.collect{|r| r.id.to_s}

    sql =  "EXISTS(SELECT #{Member.table_name}.id "
    sql << "FROM #{Member.table_name} INNER JOIN member_roles ON member_roles.member_id = members.id "
    sql << "WHERE #{sql_for_field('role_id', operator, roles, 'member_roles', 'role_id', false)} "
    sql << "AND #{Member.table_name}.user_id = #{Issue.table_name}.assigned_to_id "
    sql << "AND #{Member.table_name}.project_id = #{Issue.table_name}.project_id) "
    return sql
  end

  def sql_for_spent_estimated_timeentries_field(field, operator, value)
    db_table = ''
    db_field = "(COALESCE(COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0) / COALESCE(#{Issue.table_name}.estimated_hours, 0), 0) * 100)"
    sql = sql_for_field('spent_estimated_timeentries', operator, value, db_table, db_field)
    return sql
  end

  def sql_for_sum_of_timeentries_field(field, operator, value)
    db_table = ''
    db_field = "COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0)"
    sql = sql_for_field('sum_timeentries', operator, value, db_table, db_field)
    return sql
  end

  def sql_for_is_private_field(field, operator, value)
    op = (operator == "=" ? 'IN' : 'NOT IN')
    va = value.map {|v| v == '0' ? connection.quoted_false : connection.quoted_true}.uniq.join(',')
    "#{Issue.table_name}.is_private #{op} (#{va})"
  end

  def sql_for_not_updated_on_field(field, operator, value)
    db_field = 'updated_on'
    db_table = self.entity.table_name

    if operator =~ /date_period_([12])/
      if $1 == '1' && value[:period].to_sym == :all
        "#{Issue.quoted_table_name}.#{db_field} = #{Issue.quoted_table_name}.created_on"
      else
        period_dates = self.get_date_range($1, value[:period], value[:from], value[:to])
        self.reversed_date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day))
      end
    else
      nil
    end
  end

  def sql_for_participant_id_field(field, operator, value)
    filters_clauses = []
    ['assigned_to_id', 'author_id', 'watcher_id'].each do |part_field|
      v = value
      if part_field == 'assigned_to_id'
        if v.is_a?(Array)
          additional = []
          v.each do |user_id|
            user = User.where(:id => user_id).first
            additional |= user.group_ids.map(&:to_s)
          end
          v += additional
        end
      end

      custom_sql = self.get_custom_sql_for_field(part_field, operator, v)
      unless custom_sql.blank?
        filters_clauses << custom_sql
        next
      end

      if respond_to?("sql_for_#{part_field}_field")
        # specific statement
        filters_clauses << send("sql_for_#{part_field}_field", part_field, operator, v)
      else
        db_table = self.entity.table_name
        db_field = part_field
        returned_sql_for_field = self.sql_for_field(part_field, operator, v, db_table, db_field)
        filters_clauses << ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
      end
    end
    '(' + filters_clauses.join(' OR ') + ')'
  end

  def sql_for_relations(field, operator, value, options={})
    relation_options = IssueRelation::TYPES[field]
    return relation_options unless relation_options

    relation_type = field
    join_column, target_join_column = 'issue_from_id', 'issue_to_id'
    if relation_options[:reverse] || options[:reverse]
      relation_type = relation_options[:reverse] || relation_type
      join_column, target_join_column = target_join_column, join_column
    end

    sql = case operator
    when '*', '!*'
      op = (operator == '*' ? 'IN' : 'NOT IN')
      "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.relation_type = '#{connection.quote_string(relation_type)}')"
    when '=', '!'
      op = (operator == '=' ? 'IN' : 'NOT IN')
      "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.relation_type = '#{connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = #{value.first.to_i})"
    when '=p', '=!p', '!p'
      op = (operator == '!p' ? 'NOT IN' : 'IN')
      comp = (operator == '=!p' ? '<>' : '=')
      "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.relation_type = '#{connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.project_id #{comp} #{value.first.to_i})"
    end

    if relation_options[:sym] == field && !options[:reverse]
      sqls = [sql, sql_for_relations(field, operator, value, :reverse => true)]
      sql = sqls.join(["!", "!*", "!p"].include?(operator) ? " AND " : " OR ")
    end
    "(#{sql})"
  end

  IssueRelation::TYPES.keys.each do |relation_type|
    alias_method "sql_for_#{relation_type}_field".to_sym, :sql_for_relations
  end

end
