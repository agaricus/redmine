require_dependency 'query'

# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
# DEPRECATED ! Use EasyProjectQuery instead.
class ProjectQueryColumn < QueryColumn
end

class ProjectQueryCustomFieldColumn < QueryCustomFieldColumn
end

class ProjectQuery < ActiveRecord::Base
  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  self.table_name = 'projectqueries'

  belongs_to :user

  serialize :filters
  serialize :column_names
  serialize :sort_criteria, Array

  attr_protected :user_id

  validates_presence_of :name, :on => :save
  validates_length_of :name, :maximum => 255

  @@operators = { "="   => :label_equals,
    "!"   => :label_not_equals,
    "o"   => :label_open_issues,
    "c"   => :label_closed_issues,
    "!*"  => :label_none,
    "*"   => :label_all,
    ">="  => :label_greater_or_equal,
    "<="  => :label_less_or_equal,
    "<t+" => :label_in_less_than,
    ">t+" => :label_in_more_than,
    "t+"  => :label_in,
    "t"   => :label_today,
    "w"   => :label_this_week,
    ">t-" => :label_less_than_ago,
    "<t-" => :label_more_than_ago,
    "t-"  => :label_ago,
    "~"   => :label_contains,
    "!~"  => :label_not_contains }

  cattr_reader :operators

  @@operators_by_filter_type = { :list => [ "=", "!" ],
    :list_status => [ "o", "=", "!", "c", "*" ],
    :list_optional => [ "=", "!", "!*", "*" ],
    :list_subprojects => [ "*", "!*", "=" ],
    :date => [ "<t+", ">t+", "t+", "t", "w", ">t-", "<t-", "t-" ],
    :date_past => [ ">t-", "<t-", "t-", "t", "w" ],
    :string => [ "=", "~", "!", "!~" ],
    :text => [  "~", "!~" ],
    :integer => [ "=", ">=", "<=", "!*", "*" ] }

  cattr_reader :operators_by_filter_type

  @@available_columns = [
    ProjectQueryColumn.new(:name, :sortable => "#{Project.table_name}.name"),
    ProjectQueryColumn.new(:description, :sortable => "#{Project.table_name}.description"),
    ProjectQueryColumn.new(:status),
    ProjectQueryColumn.new(:predicted_cost, :sortable => "#{Project.table_name}.predicted_cost", :groupable => true),
    ProjectQueryColumn.new(:easy_due_date, :sortable => "#{Project.table_name}.easy_due_date", :default_order => 'desc'),
    ProjectQueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on", :default_order => 'desc')
  ]
  cattr_reader :available_columns

  def initialize(attributes = nil)
    warn "[DEPRECATION] 'ProjectQuery' is deprecated.  Please use 'EasyProjectQuery' instead."
    super attributes
    self.filters ||= { 'status' => {:operator => "=", :values => [Project::STATUS_ACTIVE.to_s]} }
  end

  def validate
    filters.each_key do |field|
      errors.add label_for(field), :blank unless
      # filter requires one or more values
      (values_for(field) and !values_for(field).first.blank?) or
        # filter doesn't require any value
      ["o", "c", "!*", "*", "t", "w"].include? operator_for(field)
    end if filters
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (!is_public && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public # && !@is_for_all && user.allowed_to?(:manage_public_queries, project)
  end

  # edit by lukas
  def available_filters
    return @available_filters if @available_filters

    @available_filters = { #"status" => { :type => :list, :order => 1, :values => [[l(:status_active), 1], [l(:status_archived), 9]]},
      "role_id" => { :type => :list, :order => 6, :values => Role.all.collect{|r| [r.name, r.id.to_s]} },
      "name" => { :type => :text, :order => 8 },
      "created_on" => { :type => :date_past, :order => 9 },
      "updated_on" => { :type => :date_past, :order => 10 },
      "easy_due_date" => { :type => :date, :order => 12 },
      "predicted_cost" => { :type => :integer, :order => 13 }
    }

    user_values = []
    user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    if User.current.admin?
      user_values += User.active.sorted.collect{|s| [s.name, s.id.to_s] }
    else
      user_values += User.current.projects.collect(&:users).flatten.uniq.sort_by(&:name).collect{|s| [s.name, s.id.to_s] }
    end


    add_custom_fields_filters(ProjectCustomField.find(:all, :conditions => {:is_filter => true}))

    # edit by lukas (add autor)
    @available_filters["member_id"] = { :type => :list, :order => 5, :values => user_values } unless user_values.empty?

    @available_filters
  end

  def add_filter(field, operator, values)
    # values must be an array
    return unless values and values.is_a? Array # and !values.first.empty?
    # check if field is defined as an available filter
    if available_filters.has_key? field
      filter_options = available_filters[field]
      # check if operator is allowed for that filter
      #if @@operators_by_filter_type[filter_options[:type]].include? operator
      #  allowed_values = values & ([""] + (filter_options[:values] || []).collect {|val| val[1]})
      #  filters[field] = {:operator => operator, :values => allowed_values } if (allowed_values.first and !allowed_values.first.empty?) or ["o", "c", "!*", "*", "t"].include? operator
      #end
      filters[field] = {:operator => operator, :values => values }
    end
  end

  def add_short_filter(field, expression)
    return unless expression
    parms = expression.scan(/^(o|c|!\*|!|\*)?(.*)$/).first
    add_filter field, (parms[0] || "="), [parms[1] || ""]
  end

  def has_filter?(field)
    filters and filters[field]
  end

  def operator_for(field)
    has_filter?(field) ? filters[field][:operator] : nil
  end

  def values_for(field)
    has_filter?(field) ? filters[field][:values] : nil
  end

  def label_for(field)
    label = available_filters[field][:name] if available_filters.has_key?(field)
    label ||= field.gsub(/\_id$/, "")
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = ProjectQuery.available_columns
    @available_columns += ProjectCustomField.find(:all).collect {|cf| ProjectQueryCustomFieldColumn.new(cf) }
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    available_columns.select {|c| c.groupable}
  end

  def columns
    if has_default_columns?
      available_columns.select do |c|
        # Adds the project column by default for cross-project lists
        EasySetting.value('project_list_default_columns').include?(c.name.to_s)
      end
    else
      # preserve the column_names order
      column_names.collect {|name| available_columns.find {|col| col.name == name}}.compact
    end
  end

  def column_names=(names)
    if names
      names = names.select {|n| n.is_a?(Symbol) || !n.blank? }
      names = names.collect {|n| n.is_a?(Symbol) ? n : n.to_sym }
      # Set column_names to nil if default columns
      if names.map(&:to_s) == EasySetting.value('project_list_default_columns')
        names = nil
      end
    end
    write_attribute(:column_names, names)
  end

  def has_column?(column)
    column_names && column_names.include?(column.name)
  end

  def has_default_columns?
    column_names.nil? || column_names.empty?
  end

  def sort_criteria=(arg)
    c = []
    if arg.is_a?(Hash)
      arg = arg.keys.sort.collect {|k| arg[k]}
    end
    c = arg.select {|k,o| !k.to_s.blank?}.slice(0,3).collect {|k,o| [k.to_s, o == 'desc' ? o : 'asc']}
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    read_attribute(:sort_criteria) || []
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if grouped? && (column = group_by_column)
      column.sortable.is_a?(Array) ?
        column.sortable.collect {|s| "#{s} #{column.default_order}"}.join(',') :
        "#{column.sortable} #{column.default_order}"
    end
  end

  # Returns true if the query is a grouped query
  def grouped?
    !group_by.blank?
  end

  def group_by_column
    groupable_columns.detect {|c| c.name.to_s == group_by}
  end

  def group_by_statement
    group_by_column.groupable
  end

  def project_statement
    project_clauses = []
    project_clauses << Project.allowed_to_condition(User.current, :view_issues)
    project_clauses.join(' AND ')
  end

  def statement
    # filters clauses
    filters_clauses = []
    my_fields = ['member_id', 'role_id'] & filters.keys

    unless my_fields.blank?
      sql = ''

      sql << "#{Project.table_name}.id IN (SELECT DISTINCT pm1.project_id
FROM members pm1
INNER JOIN member_roles pmr1 ON pmr1.member_id = pm1.id
WHERE 1=1 "
      if my_fields.include?('member_id')
        mv = values_for('member_id').dup
        mv.push(User.current.logged? ? User.current.id.to_s : "0") if mv.delete("me")
        sql << (' AND ' + sql_for_field('member_id', operator_for('member_id'), mv, 'pm1', 'user_id', true))
      end
      sql << (' AND ' + sql_for_field('role_id', operator_for('role_id'), values_for('role_id').dup, 'pmr1', 'role_id', true)) if my_fields.include?('role_id')
      sql << ')'

      filters_clauses << sql
    end

    filters.each_key do |field|
      next if ['subproject_id', 'member_id', 'role_id'].include?(field)
      v = values_for(field).dup
      next unless v and !v.empty?
      operator = operator_for(field)

      # "me" value subsitution
      if %w(assigned_to_id member_id watcher_id).include?(field)
        v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")
      end

      sql = ''
      if field =~ /^cf_(\d+)$/
        # custom field
        db_table = CustomValue.table_name
        db_field = 'value'
        is_custom_filter = true
        sql << "#{Project.table_name}.id IN (SELECT #{Project.table_name}.id FROM #{Project.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Project' AND #{db_table}.customized_id=#{Project.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
        sql << sql_for_field(field, operator, v, db_table, db_field, true) + ')'
      elsif field == 'watcher_id'
        db_table = Watcher.table_name
        db_field = 'user_id'
        sql << "#{Project.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Project' AND "
        sql << sql_for_field(field, '=', v, db_table, db_field) + ')'
      else
        # regular field
        db_table = Project.table_name
        db_field = field
        sql << '(' + sql_for_field(field, operator, v, db_table, db_field) + ')'
      end
      filters_clauses << sql

    end if filters and valid?

    #(filters_clauses << project_statement).join(' AND ')
    filters_clauses.join(' AND ')
  end

  # Returns the project count
  def project_count
    Project.count(:conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the project count by group or nil if query is not grouped
  def project_count_by_group
    return @project_count_by_group if @project_count_by_group
    r = nil
    if grouped?
      begin
        # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = Project.count(:group => group_by_statement, :conditions => statement)
      rescue ActiveRecord::RecordNotFound
        r = {nil => project_count}
      end
      c = group_by_column
      if c.is_a?(ProjectQueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    @project_count_by_group = r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the projects
  # Valid options are :order, :offset, :limit, :include, :conditions
  def projects(options={})
    order_option = [group_by_sort_order, options[:order]].reject {|s| s.blank?}.join(',')
    order_option = nil if order_option.blank?

    Project.visible.find :all, :include => ((options[:include] || [])).uniq,
      :conditions => ProjectQuery.merge_conditions(statement, options[:conditions]),
      :order => order_option,
      :limit  => options[:limit],
      :offset => options[:offset]
  end

  def to_new_easy_query
    EasyProjectQuery.new(:name => name, :filters => filters,
      :user_id => user_id, :visibility => visibility, :column_names => column_names,
      :sort_criteria => sort_criteria, :group_by => group_by)
  end

  private

  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
    #puts "sql_for_field: field=#{field}, operator=#{operator}, value=#{value}, db_table=#{db_table}, db_field=#{db_field}, is_custom_filter=#{is_custom_filter}"
    sql = ''
    case operator
    when "="
      sql = "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
    when "!"
      sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
    when "!*"
      sql = "#{db_table}.#{db_field} IS NULL"
      sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
    when "*"
      sql = "#{db_table}.#{db_field} IS NOT NULL"
      sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
    when ">="
      sql = "#{db_table}.#{db_field} >= #{value.first.to_i}"
    when "<="
      sql = "#{db_table}.#{db_field} <= #{value.first.to_i}"
    when "o"
      sql = "#{Project.table_name}.status=1" if field == "status"
    when "c"
      sql = "#{Project.table_name}.status=0" if field == "status"
    when ">t-"
      sql = date_range_clause(db_table, db_field, - value.first.to_i, 0)
    when "<t-"
      sql = date_range_clause(db_table, db_field, nil, - value.first.to_i)
    when "t-"
      sql = date_range_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
    when ">t+"
      sql = date_range_clause(db_table, db_field, value.first.to_i, nil)
    when "<t+"
      sql = date_range_clause(db_table, db_field, 0, value.first.to_i)
    when "t+"
      sql = date_range_clause(db_table, db_field, value.first.to_i, value.first.to_i)
    when "t"
      sql = date_range_clause(db_table, db_field, 0, 0)
    when "w"
      from = l(:general_first_day_of_week) == '7' ?
        # week starts on sunday
      ((Date.today.cwday == 7) ? Time.now.at_beginning_of_day : Time.now.at_beginning_of_week - 1.day) :
        # week starts on monday (Rails default)
      Time.now.at_beginning_of_week
      sql = "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(from + 7.days)]
    when "~"
      sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    when "!~"
      sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    end

    return sql
  end

  def add_custom_fields_filters(custom_fields)
    @available_filters ||= {}

    custom_fields.select(&:is_filter?).each do |field|
      case field.field_format
      when "text"
        options = { :type => :text, :order => 20 }
      when "list"
        options = { :type => :list_optional, :values => field.possible_values, :order => 20}
      when "date"
        options = { :type => :date, :order => 20 }
      when "bool"
        options = { :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
      else
        options = { :type => :string, :order => 20 }
      end
      @available_filters["cf_#{field.id}"] = options.merge({ :name => field.name })
    end
  end

  # Returns a SQL clause for a date or datetime field.
  def date_range_clause(table, field, from, to)
    s = []
    if from
      s << ("#{table}.#{field} > '%s'" % [connection.quoted_date((Date.yesterday + from).to_time.end_of_day)])
    end
    if to
      s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date((Date.today + to).to_time.end_of_day)])
    end
    s.join(' AND ')
  end

end

