require_dependency 'query'

# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
# DEPRECATED ! Use EasyUserQuery instead.
class UserQueryColumn < QueryColumn
end

class UserQueryCustomFieldColumn < QueryCustomFieldColumn
end

class UserQuery < ActiveRecord::Base
  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  self.table_name = 'userqueries'

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
    UserQueryColumn.new(:login, :sortable => "#{User.table_name}.login"),
    UserQueryColumn.new(:firstname,:sortable => "#{User.table_name}.firstname", :groupable => true),
    UserQueryColumn.new(:lastname, :sortable => "#{User.table_name}.lastname"),
    UserQueryColumn.new(:mail, :sortable => "#{User.table_name}.mail"),
    UserQueryColumn.new(:admin, :sortable => "#{User.table_name}.admin", :groupable => true),
    UserQueryColumn.new(:cached_group_names, :sortable => "#{User.table_name}.cached_group_names", :groupable => true),
    UserQueryColumn.new(:last_login_on, :sortable => "#{User.table_name}.last_login_on", :groupable => true),
    UserQueryColumn.new(:created_on, :sortable => "#{User.table_name}.created_on", :groupable => true)
  ]
  cattr_reader :available_columns

  def initialize(attributes = nil)
    warn "[DEPRECATION] 'UserQuery' is deprecated.  Please use 'EasyUserQuery' instead."
    super attributes
    self.filters ||= { 'status' => {:operator => "=", :values => [User::STATUS_ACTIVE.to_s]} }
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

  def available_filters
    return @available_filters if @available_filters
    user_count_by_status = User.count(:group => 'status').to_hash
    @available_filters = { "status" => { :type => :list, :order => 1, :values => [
          ["#{l(:status_active)} (#{user_count_by_status[1].to_i})", '1'],
          ["#{l(:status_registered)} (#{user_count_by_status[2].to_i})", '2'],
          ["#{l(:status_locked)} (#{user_count_by_status[3].to_i})", '3']]},
      "login" => { :type => :text, :order => 7},
      "firstname" => { :type => :text, :order => 8 },
      "lastname" => { :type => :text, :order => 9 },
      "admin" => { :type => :list,:values => [[l(:label_all), ''],["#{l(:general_text_Yes)}", '1'],["#{l(:general_text_No)}", '0']], :order => 10 },
      "created_on" => { :type => :date_past, :order => 11},
      "groups" => {:type => :list, :order => 20,:values => Group.all.collect{|g| [g.lastname, g.id.to_s] } }
    }
    add_custom_fields_filters(UserCustomField.find(:all, :conditions => {:is_filter => true}))


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
    @available_columns = UserQuery.available_columns
    @available_columns += UserCustomField.find(:all).collect {|cf| UserQueryCustomFieldColumn.new(cf) }
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    available_columns.select {|c| c.groupable}
  end

  def columns
    if has_default_columns?
      available_columns.select do |c|
        # Adds the project column by default for cross-project lists
        EasySetting.value('user_list_default_columns').include?(c.name.to_s)
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
      if names.map(&:to_s) == EasySetting.value('user_list_default_columns')
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
    project_clauses << User.allowed_to_condition(User.current, :view_issues)
    project_clauses.join(' AND ')
  end

  def statement
    # filters clauses
    filters_clauses = []
    filters.each_key do |field|
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
        sql << "#{User.table_name}.id IN (SELECT #{User.table_name}.id FROM #{User.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Principal' AND #{db_table}.customized_id=#{User.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
        sql << sql_for_field(field, operator, v, db_table, db_field, true) + ')'
      elsif field == "groups" # filter groups. Display users in select group
        db_table = 'groups_users'
        db_field = 'group_id'
        sql << "#{User.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.user_id FROM #{db_table} WHERE #{db_table}.group_id = #{v} AND "
        sql << sql_for_field(field, operator, v, db_table, db_field) + ')'
      elsif field == "status" && v == '' # filter groups. Display users in select group
        nv = ['0','1','2','3']
        db_table = User.table_name
        db_field = field
        sql << '(' + sql_for_field(field, operator, nv, db_table, db_field) + ')'

      else
        # regular field
        db_table = User.table_name
        db_field = field
        sql << '(' + sql_for_field(field, operator, v, db_table, db_field) + ')'
      end
      filters_clauses << sql

    end if filters and valid?

    #(filters_clauses << User_statement).join(' AND ')
    filters_clauses.join(' AND ')
  end

  # Returns the project count
  def user_count
    User.count(:conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the project count by group or nil if query is not grouped
  def user_count_by_group
    r = nil
    if grouped?
      begin
        # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = User.count(:group => group_by_statement, :conditions => statement)
      rescue ActiveRecord::RecordNotFound
        r = {nil => user_count}
      end
      c = group_by_column
      if c.is_a?(UserQueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the users
  # Valid options are :order, :offset, :limit, :include, :conditions
  def users(options={})
    order_option = [group_by_sort_order, options[:order]].reject {|s| s.blank?}.join(',')
    order_option = nil if order_option.blank?

    User.find :all, :include => ((options[:include] || [])).uniq,
      :conditions => UserQuery.merge_conditions(statement, options[:conditions]),
      :order => order_option,
      :limit  => options[:limit],
      :offset => options[:offset]
  end

  def to_new_easy_query
    EasyUserQuery.new(:name => name, :filters => filters,
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
      sql = "#{User.table_name}.status=1" if field == "status"
    when "c"
      sql = "#{User.table_name}.status=0" if field == "status"
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

