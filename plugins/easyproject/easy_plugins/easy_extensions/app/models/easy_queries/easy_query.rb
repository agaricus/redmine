require_dependency 'utils/dateutils'

class EasyQueryColumn < EasyEntityAttribute
  include EasyEntityAttributeColumnExtensions
end

class EasyQueryCustomFieldColumn < EasyEntityCustomAttribute
  include EasyEntityCustomAttributeColumnExtensions
end

class EasyQuery < ActiveRecord::Base

  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  include EasyUtils::DateUtils

  VISIBILITY_PRIVATE = 0
  VISIBILITY_ROLES   = 1
  VISIBILITY_PUBLIC  = 2

  belongs_to :project
  belongs_to :user
  has_and_belongs_to_many :roles, :join_table => "#{table_name_prefix}easy_queries_roles#{table_name_suffix}", :foreign_key => 'easy_query_id'

  serialize :filters, Hash
  serialize :column_names, Array
  serialize :sort_criteria, Array
  serialize :settings, Hash

  attr_accessor :additional_statement
  attr_accessor :display_filter_columns_on_index, :display_filter_group_by_on_index, :display_filter_sort_on_index
  attr_accessor :display_filter_columns_on_edit, :display_filter_group_by_on_edit, :display_filter_sort_on_edit
  attr_accessor :display_filter_fullscreen_button, :display_save_button
  attr_accessor :display_project_column_if_project_missing
  attr_accessor :easy_query_entity_controller, :easy_query_entity_partial_view, :export_formats
  attr_writer   :easy_query_entity_action
  attr_accessor :use_free_search, :free_search_question, :free_search_tokens

  validates :name, :presence => true, :on => :save
  validates_length_of :name, :maximum => 255
  validates :visibility, :inclusion => { :in => [VISIBILITY_PUBLIC, VISIBILITY_ROLES, VISIBILITY_PRIVATE] }
  validate :validate_query_filters
  validate do |query|
    errors.add(:base, l(:label_role_plural) + ' ' + l('activerecord.errors.messages.blank')) if query.visibility == VISIBILITY_ROLES && roles.blank?
  end

  after_initialize :query_after_initialize

  after_save do |query|
    if query.visibility_changed? && query.visibility != VISIBILITY_ROLES
	    query.roles.clear
	  end
  end

  class_attribute :registered_subclasses
  self.registered_subclasses = {}

  class_attribute :operators
  self.operators = {
    "="   => :label_equals,
    "!"   => :label_not_equals,
    "o"   => :label_open_issues,
    "c"   => :label_closed_issues,
    "!*"  => :label_none,
    "*"   => :label_any,
    ">="  => :label_greater_or_equal,
    "<="  => :label_less_or_equal,
    "><"  => :label_between,
    "<t+" => :label_in_less_than,
    ">t+" => :label_in_more_than,
    "><t+"=> :label_in_the_next_days,
    "t+"  => :label_in,
    "t"   => :label_today,
    "ld"  => :label_yesterday,
    "w"   => :label_this_week,
    "lw"  => :label_last_week,
    "l2w" => [:label_last_n_weeks, {:count => 2}],
    "m"   => :label_this_month,
    "lm"  => :label_last_month,
    "y"   => :label_this_year,
    ">t-" => :label_less_than_ago,
    "<t-" => :label_more_than_ago,
    "><t-"=> :label_in_the_past_days,
    "t-"  => :label_ago,
    "~"   => :label_contains,
    "!~"  => :label_not_contains,
    "=p"  => :label_any_issues_in_project,
    "=!p" => :label_any_issues_not_in_project,
    "!p"  => :label_no_issues_in_project
  }

  class_attribute :operators_by_filter_type
  self.operators_by_filter_type = {
    :list => [ "=", "!" ],
    :list_status => [ "o", "=", "!", "c", "*" ],
    :list_optional => [ "=", "!", "!*", "*" ],
    :list_subprojects => [ "*", "!*", "=" ],
    :date => [ "=", ">=", "<=", "><", "<t+", ">t+", "><t+", "t+", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", ">t-", "<t-", "><t-", "t-", "!*", "*" ],
    :date_past => [ "=", ">=", "<=", "><", ">t-", "<t-", "><t-", "t-", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", "!*", "*" ],
    :date_period => ['date_period_1', 'date_period_2'],
    :string => [ "=", "~", "!", "!~", "!*", "*" ],
    :text => [  "~", "!~", "!*", "*" ],
    :integer => [ "=", ">=", "<=", "><", "!*", "*" ],
    :float => [ "=", ">=", "<=", "><", "!*", "*" ],
    :relation => ["=", "=p", "=!p", "!p", "!*", "*"],
    :easy_lookup => [ '=', '!' ]
  }

  def self.visible(user = nil, options = {})
    user ||=  User.current

    scope = includes(:project)

    if permission_view_entities.nil?
      scope = scope.where("#{table_name}.project_id IS NULL")
    else
      base = Project.allowed_to_condition(user, permission_view_entities, options)
      scope = scope.where("#{table_name}.project_id IS NULL OR (#{base})")
    end

    if user.admin?
      scope.where("#{table_name}.visibility <> ? OR #{table_name}.user_id = ?", VISIBILITY_PRIVATE, user.id)
    elsif user.memberships.any?
      scope.where("#{table_name}.visibility = ?" +
          " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
          "SELECT DISTINCT q.id FROM #{table_name} q" +
          " INNER JOIN #{table_name_prefix}queries_roles#{table_name_suffix} qr on qr.query_id = q.id" +
          " INNER JOIN #{MemberRole.table_name} mr ON mr.role_id = qr.role_id" +
          " INNER JOIN #{Member.table_name} m ON m.id = mr.member_id AND m.user_id = ?" +
          " WHERE q.project_id IS NULL OR q.project_id = m.project_id))" +
          " OR #{table_name}.user_id = ?",
        VISIBILITY_PUBLIC, VISIBILITY_ROLES, user.id, user.id)
    elsif user.logged?
      scope.where("#{table_name}.visibility = ? OR #{table_name}.user_id = ?", VISIBILITY_PUBLIC, user.id)
    else
      scope.where("#{table_name}.visibility = ?", VISIBILITY_PUBLIC)
    end
  end

  def self.sidebar_queries(visibility, user = nil, project = nil, options = {})
    visible(user, options).where(["#{table_name}.visibility = ?", visibility]).
      where(project.nil? ? ['project_id IS NULL'] : ['project_id IS NULL OR project_id = ?', project.id]).
      select([:id, :name, :sort_criteria, :project_id, :type]).
      order("#{table_name}.name ASC")
  end

  def self.private_queries(user = nil, project = nil, options = {})
    sidebar_queries(VISIBILITY_PRIVATE, user, project, options)
  end

  def self.public_queries(user = nil, project = nil, options = {})
    sidebar_queries(VISIBILITY_PUBLIC, user, project, options)
  end

  def self.role_queries(user = nil, project = nil, options = {})
    sidebar_queries(VISIBILITY_ROLES, user, project, options)
  end

  #TO OVERRIDE!
  def available_columns; end;
  def available_filters; end;
  def entity; end;
  def default_find_include; []; end;
  def default_find_joins; []; end;

  def default_list_columns
    @default_list_columns ||= (get_default_values_from_easy_settings('list_default_columns') || Array.new)
  end

  def searchable_columns
    []
  end

  def columns_with_me
    ['assigned_to_id', 'author_id', 'watcher_id']
  end

  # OTHERS

  def initialize(attributes = nil)
    super attributes
    raise ArgumentError, 'You have override entity method!' if self.entity.nil?
    raise ArgumentError, 'You have override available_columns method!' if self.available_columns.blank?
    #    raise ArgumentError, 'You have override default_list_columns method!' if self.default_list_columns.blank?
    self.filters = self.default_filter if self.filters.blank?
  end

  def query_after_initialize
    self.additional_statement = ''
    self.display_filter_columns_on_index, self.display_filter_group_by_on_index, self.display_filter_sort_on_index = true, true, false
    self.display_filter_columns_on_edit, self.display_filter_group_by_on_edit, self.display_filter_sort_on_edit = true, true, true
    self.display_filter_fullscreen_button, self.display_save_button = true, true
    self.display_project_column_if_project_missing = true
    self.easy_query_entity_controller = self.entity.name.underscore.pluralize
    self.easy_query_entity_partial_view = 'easy_queries/easy_query_entities_list'
    self.name.force_encoding('UTF-8') if self.name.respond_to?(:force_encoding)

    export = ActiveSupport::OrderedHash.new
    export[:csv] = {}
    export[:pdf] = {}
    self.export_formats = export
  end

  def easy_query_entity_action
    @easy_query_entity_action || 'index'
  end

  def self.map(&block)
    yield self
  end

  def self.register(query_class, options={})
    # EasySetting required ['default_sorting_array', 'default_filters', 'list_default_columns', 'grouped_by']
    registered_subclasses[query_class] = options if registered_subclasses[query_class].nil?
  end

  def self.entity_css_classes(entity, options={})
    entity.css_classes if entity.respond_to?(:css_classes)
  end

  def self.permission_view_entities
    nil
  end

  def validate_query_filters
    filters.each_key do |field|
      if values_for(field)
        case type_for(field)
        when :integer
          add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^[+-]?\d+$/) }
        when :float
          add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^[+-]?\d+(\.\d*)?$/) }
        when :date, :date_past
          case operator_for(field)
          when '=', '>=', '<=', '><'
            add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && (!v.match(/^\d{4}-\d{2}-\d{2}$/) || (Date.parse(v) rescue nil).nil?) }
          when '>t-', '<t-', 't-', '>t+', '<t+', 't+', '><t+', '><t-'
            add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^\d+$/) }
          end
        end
      end
    end if filters
  end

  def add_filter_error(field, message)
    m = label_for(field) + " " + l(message, :scope => 'activerecord.errors.messages')
    errors.add(:base, m)
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (self.is_private? && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    self.is_public? && !@is_for_all && user.allowed_to?(:manage_public_queries, self.project)
  end

  def visible?(user=User.current)
    return true if user.admin?
    return false unless project.nil? || user.allowed_to?(self.class.permission_view_entities, project, :global => true)
    case visibility
    when VISIBILITY_PUBLIC
      true
    when VISIBILITY_ROLES
      if project
        (user.roles_for_project(project) & roles).any?
      else
        Member.where(:user_id => user.id).joins(:roles).where(:member_roles => {:role_id => roles.map(&:id)}).any?
      end
    else
      user == self.user
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  # Returns a representation of the available filters for JSON serialization
  def available_filters_as_json
    json = {}
    available_filters.each do |field, options|
      json[field] = options.slice(:type, :name, :values).stringify_keys
    end
    json
  end

  # Get values from Proc, select only valid filters, sort and cache list of filters. Return array of arrays
  def filters_for_select
    @filters_for_select ||= self.available_filters.select do |filter, options|
      self.available_filters[filter][:values] = options[:values].call if options[:values].is_a?(Proc)

      !([:list, :list_optional, :list_status, :list_subprojects].include?(options[:type]) && self.available_filters[filter][:values].blank?)
    end.sort{|a,b| a[1][:order]<=>b[1][:order]}

    return @filters_for_select
  end

  def projects_for_select(projects = nil, cache = true)
    return @project_values if @project_values.present? && cache
    @project_values = Array.new
    Project.each_with_easy_level(projects || Project.visible.non_templates.all) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      @project_values << ["#{prefix}#{p.name}", p.id.to_s]
    end

    return @project_values
  end

  def all_projects
    @all_projects ||= Project.visible.non_templates.select([:id, :name, :easy_level]).all
  end

  def all_projects_values
    return @all_projects_values if @all_projects_values
    values = []
    Project.each_with_easy_level(all_projects) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      values << ["#{prefix}#{p.name}", p.id.to_s]
    end
    @all_projects_values = values
  end

  def add_filter(field, operator, values)
    return if !self.available_filters.key?(field)
    values ||= ['']
    if RUBY_VERSION >= '1.9'
      if values.is_a?(String)
        values.force_encoding('UTF-8')
      elsif values.is_a?(Array)
        values = values.collect{|x| x.force_encoding('UTF-8')}
      end
    end
    self.filters[field] = {:operator => operator.to_s, :values => (values || [''])}
  end

  def add_short_filter(field, expression)
    return unless expression && self.available_filters.has_key?(field)
    field_type = self.available_filters[field][:type]
    if field_type == :date_period
      e = expression.split('|')

      if e.size == 1
        if e[0].match(/\d{4}/) && (from_date = Date.parse(e[0]) rescue nil)
          self.add_filter(field, 'date_period_2', {:from => from_date, :to => from_date})
        else
          self.add_filter(field, 'date_period_1', self.get_date_range('1', e[0]).merge(:period => e[0]))
        end
      elsif e.size == 2
        from_date = begin; Date.parse(e[0]); rescue; nil; end unless e[0].blank?
        to_date = begin; Date.parse(e[1]); rescue; nil; end unless e[1].blank?
        self.add_filter(field, 'date_period_2', {:from => from_date, :to => to_date})
      end
    else
      self.operators_by_filter_type[field_type].sort.reverse.detect do |operator|
        next unless expression =~ /^#{Regexp.escape(operator)}(.*)$/
        self.add_filter field, operator, $1.present? ? $1.split('|') : ['']
      end || self.add_filter(field, '=', expression.split('|'))
    end
  end

  # Add multiple filters using +add_filter+
  def add_filters(fields, operators, values)
    if fields.is_a?(Array) && operators.is_a?(Hash) && (values.nil? || values.is_a?(Hash))
      fields.each do |field|
        self.add_filter(field, operators[field], values && values[field])
      end
    end
  end

  def has_filter?(field)
    self.filters and self.filters[field]
  end

  def filters_active?
    return self.filters != self.default_filter || (self.grouped? && self.default_group_by != self.group_by) || !self.sort_criteria.blank?
  end

  def type_for(field)
    self.available_filters[field][:type] if self.available_filters.has_key?(field)
  end

  def operator_for(field)
    self.has_filter?(field) ? self.filters[field][:operator] : nil
  end

  def values_for(field)
    if self.has_filter?(field)
      self.filters[field][:values] = self.filters[field][:values].call if self.filters[field][:values].is_a?(Proc)

      field_values = self.filters[field][:values]
      field_values || []
    else
      nil
    end
  end

  def value_for(field, index=0)
    (self.values_for(field) || [])[index]
  end

  def label_for(field)
    label = self.available_filters[field][:name] if self.available_filters.has_key?(field)
    label ||= field.gsub(/\_id$/, "")
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    self.available_columns.select {|c| c.groupable}
  end

  # Returns a Hash of columns and the key for sorting
  def sortable_columns
    self.available_columns.inject({}) {|h, column|
      h[column.name.to_s] = column.sortable
      h
    }
  end

  def sumable_columns
    return available_columns.select {|c| c.sumable_top? || c.sumable_bottom? }.uniq
  end

  def sumable_columns_top
    return available_columns.select {|c| c.sumable_top? }
  end

  def sumable_columns_bottom
    return available_columns.select {|c| c.sumable_bottom? }
  end

  def sumable_columns_header
    return available_columns.select {|c| c.sumable_header? }
  end

  def inline_columns
    columns.select(&:inline?)
  end

  def block_columns
    columns.reject(&:inline?)
  end

  def available_inline_columns
    available_columns.select(&:inline?)
  end

  def available_block_columns
    available_columns.reject(&:inline?)
  end

  def columns
    if self.has_default_columns?
      def_columns = []
      if self.display_project_column_if_project_missing && self.project.nil? && (project_column = self.available_columns.detect{|c| c.name == :project})
        def_columns << project_column
      end
      self.default_list_columns.each{|cname| def_columns << self.available_columns.detect{|c| c.name.to_s == cname}}
      def_columns.compact.uniq
    else
      # preserve the column_names order
      self.column_names.collect {|name| self.available_columns.find {|col| col.name == name}}.compact
    end
  end

  def column_names=(names)
    if names
      names = names.select {|n| n.is_a?(Symbol) || !n.blank? }
      names = names.collect {|n| n.is_a?(Symbol) ? n : n.to_sym }
      # Set column_names to nil if default columns
      if names.map(&:to_s) == self.default_list_columns
        names = nil
      end
    end
    write_attribute(:column_names, names)
  end

  def has_column?(column)
    self.column_names && self.column_names.include?(column.is_a?(EasyQueryColumn) ? column.name : column)
  end

  def has_custom_field_column?
    columns.any? {|column| column.is_a? QueryCustomFieldColumn}
  end

  def has_default_columns?
    self.column_names.blank?
  end

  def list_columns_changed?
    return self.default_list_columns.collect(&:to_sym) != self.columns.collect(&:name)
  end

  def sort_criteria=(arg)
    c = []
    if arg.is_a?(Hash)
      arg = arg.keys.sort.collect {|k| arg[k]}
    end
    c = arg.select {|k,o| !k.to_s.blank?}.slice(0,3).collect {|k,o| [k.to_s, (o == 'desc' || o == false) ? 'desc' : 'asc']}
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    super || []
  end

  def default_sort_criteria
    @default_sort_criteria ||= (get_default_values_from_easy_settings('default_sorting_array') || Array.new)
  end

  def sort_criteria_init
    if sort_criteria.empty?
      default_sort_criteria
    else
      sort_criteria
    end
  end

  def sort_criteria_key(arg)
    self.sort_criteria && self.sort_criteria[arg] && self.sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    self.sort_criteria && self.sort_criteria[arg] && self.sort_criteria[arg].last
  end

  def sort_criteria_order_for(key)
    sort_criteria.detect {|k, order| key.to_s == k}.try(:last)
  end

  def sort_criteria_to_sql_order(criterias=sort_criteria)
    sortable_columns_sql = self.available_columns.select{|c| c.sortable?}.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}
    criterias.select{|field_name, asc_desc| !!sortable_columns_sql[field_name]}.collect{|field_name, asc_desc| (sortable_columns_sql[field_name].is_a?(Array) ? sortable_columns_sql[field_name].join(', ') : sortable_columns_sql[field_name]) + ' ' + (asc_desc || 'asc')}.join(', ')
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if self.grouped? && (column = self.group_by_column)
      order = self.sort_criteria_order_for(column.name) || column.default_order
      column.sortable.is_a?(Array) ?
        column.sortable.collect {|s| "#{s} #{order}"}.join(',') :
        "#{column.sortable} #{order}"
    end
  end

  # Returns true if the query is a grouped query
  def grouped?
    !self.group_by_column.nil?
  end

  def group_by_column
    self.groupable_columns.detect {|c| c.groupable && c.name.to_s == self.group_by}
  end

  def group_by_statement
    grouping_col = self.group_by_column
    if grouping_col.polymorphic?
      self.group_by_column.polymorphic[:name].to_s + '_id'
    else
      grouping_col && (self.group_by_column.sumable_sql || self.group_by_column.groupable)
    end
  end

  def group_additional_options
    return {} unless group_by_column && group_by_column.polymorphic?
    {:where => "#{entity.table_name}.#{group_by_column.polymorphic[:name]}_type = '#{group_by_column.polymorphic[:type]}'"}
  end

  def add_additional_statement(additional_where)
    if self.additional_statement.blank?
      self.additional_statement = additional_where
    else
      self.additional_statement << ' AND ' + additional_where
    end
  end

  def add_statement_limitation_to_ids(ids)
    entity_ids = Array.wrap(ids)
    unless entity_ids.blank?
      additional_where = "#{self.entity.table_name}.id IN (#{entity_ids.join(',')})"
      add_additional_statement(additional_where)
    end
  end

  def statement
    # filters clauses
    filters_clauses = []

    sql = self.add_statement_sql_before_filters
    filters_clauses << sql unless sql.blank?

    self.filters.each_key do |field|
      next if self.statement_skip_fields.include?(field)
      v = self.values_for(field)
      operator = self.operator_for(field)
      next if v.blank?

      if v.nil?
        v = ''
      else
        v = v.dup
      end

      if self.columns_with_me.include?(field)
        if v.is_a?(Array) && v.delete('me')
          if User.current.logged?
            v.push(User.current.id.to_s)
            v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
          else
            v.push('0')
          end
        elsif v == 'me'
          v = User.current.id.to_s
        end
      end

      if field == 'project_id'
        if !v.blank? && v.delete('mine')
          v += User.current.memberships.map(&:project_id).map(&:to_s)
        end
      end

      custom_sql = self.get_custom_sql_for_field(field, operator, v)
      unless custom_sql.blank?
        filters_clauses << custom_sql
        next
      end

      if field =~ /cf_(\d+)$/
        filters_clauses << self.sql_for_custom_field(field, operator, v, $1)
      elsif respond_to?("sql_for_#{field}_field")
        # specific statement
        filters_clauses << send("sql_for_#{field}_field", field, operator, v)
      else
        db_table = self.entity.table_name
        db_field = field
        returned_sql_for_field = self.sql_for_field(field, operator, v, db_table, db_field)
        filters_clauses << ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
      end

    end if self.filters && self.valid?

    if (c = group_by_column) && c.is_a?(EasyQueryCustomFieldColumn)
      # Excludes results for which the grouped custom field is not visible
      filters_clauses << c.custom_field.visibility_by_project_condition
    end

    filters_clauses << self.additional_statement unless self.additional_statement.blank?
    filters_clauses.reject!(&:blank?)
    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end

  def entity_scope
    self.entity
  end

  # Returns the sum of _column_ or column
  def entity_sum(column, options={})
    unless column.is_a?(EasyEntityAttribute)
      scope = merge_scope(self.new_entity_scope, options)
      return scope.sum(column)
    end

    additional_joins = column.additional_joins(entity, :array) + joins_for_order_statement(options[:group].to_s, :array)
    options[:joins] = options[:joins].to_a + additional_joins
    column_name = column.sumable_sql || column.name

    if column.sumable_options.distinct_columns?

      if options[:group].blank?
        options[:group] =  ''
        select_group = nil
      else
        group_attr      = options[:group].to_s
        association     = entity.reflect_on_association(group_attr.to_sym)
        associated      = association && association.macro == :belongs_to # only count belongs_to associations
        group_field     = associated ? association.foreign_key : group_attr
        group_alias     = entity_scope.send(:column_alias_for, group_field)
        group_column    = entity_column_for group_field
        options[:group] = entity.connection.adapter_name == 'FrontBase' ? group_alias : group_field
        options[:group]+= ', '
        select_group    = group_field + ' AS ' + group_alias
      end

      options[:group] += column.sumable_options.distinct_columns.join(', ')
      scope = merge_scope(self.new_entity_scope, options)
      scope = scope.select('MAX('+column_name.to_s+') AS result')
      scope = scope.select(select_group) if select_group
      sql = scope.send(:construct_relation_for_association_calculations).to_sql

      final_sql = 'SELECT '
      final_sql << group_alias + ', ' if select_group
      final_sql << 'SUM(result) AS result FROM ('
      final_sql << sql
      final_sql << ') AS DT1'
      final_sql << ' GROUP BY ' + group_alias if select_group

      entity_column = entity_column_for column_name

      if select_group

        res = entity.connection.select_all(final_sql)
        if association
          key_ids     = res.collect { |row| row[group_alias] }
          if key_ids.any?
            key_records = association.klass.base_class.find(key_ids)
          else
            key_records = key_ids
          end
          key_records = Hash[key_records.map { |r| [r.id, r] }]
        end

        result = {}
        res.each do |row|
          key = entity_scope.send(:type_cast_using_column, (row[group_alias]), group_column)
          key = key_records[key] if associated
          result[key] = entity_scope.send(:type_cast_using_column, (row['result']), entity_column) # (row['result'] || '0') pokud maji byt nuly videt
        end
      else
        result = entity_scope.send(:type_cast_using_column, (entity.connection.select_value(final_sql)), entity_column)
      end

      result
    else
      scope = merge_scope(self.new_entity_scope, options)
      begin
        scope.sum(column_name)
      rescue ActiveRecord::RecordNotFound
        group_attr      = options[:group].to_s
        association     = entity.reflect_on_association(group_attr.to_sym)
        associated      = association && association.macro == :belongs_to # only count belongs_to associations
        group_field     = associated ? association.foreign_key : group_attr

        options[:group] = group_field

        scope = merge_scope(self.new_entity_scope, options)
        scope.sum(column_name)
      end
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the issue count
  def entity_count(options={})
    if self.use_free_search
      self.search_freetext_count(self.free_search_tokens, options)
    else
      options[:joins] = options[:joins].to_a + self.joins_for_order_statement( (options[:group] || '').to_s, :array )
      scope = merge_scope(self.new_entity_scope, options)
      scope.count
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the issue count by group or nil if query is not grouped
  def entity_count_by_group(options={})
    r = nil
    if self.grouped?
      begin
        # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = self.entity_count({:group => self.group_by_statement, :include => self.default_find_include}.merge(options))
      rescue
        r = {nil => self.entity_count}
      end
      c = self.group_by_column
      if c.is_a?(EasyQueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def entity_sum_by_group(column, options={})
    r = Hash.new
    if grouped?
      merge_options(options, group_additional_options)
      r = entity_sum(column, {:group => self.group_by_statement}.merge(options))
    end

    return r
  end

  def new_entity_scope
    scope = self.entity_scope.where(self.statement)

    scope = scope.includes(self.default_find_include)
    scope = scope.joins(self.default_find_joins)
    self.filters.keys.each do |filter|
      f = available_filters[filter]
      if f && f[:includes]
        scope = scope.includes(f[:includes])
      end
      if f && f[:joins]
        scope = scope.joins(f[:joins])
      end
    end
    self.columns.each do |c|
      scope = scope.includes(c.includes)
    end

    possible_columns = Array.new
    possible_columns << self.group_by.to_sym if self.group_by?
    possible_columns += self.sort_criteria.collect{|s| s.first.to_sym}

    available_includes = self.available_columns.inject({}) {|memo,var| memo[var.name] = var.includes; memo}

    possible_columns.each do |c|
      if s = available_includes[c.to_sym]
        scope = scope.includes(s)
      end
    end

    scope
  end

  def create_entity_scope(options={})
    order_option = [self.group_by_sort_order, (options[:order] || self.sort_criteria_to_sql_order)].reject {|s| s.blank?}.join(',')
    order_option = nil if order_option.blank?

    scope_options = options.merge({:order => order_option, :joins => joins_for_order_statement(order_option)})
    scope = merge_scope(self.new_entity_scope, scope_options)

    scope
  end

  # Returns the issues
  # Valid options are :order, :offset, :limit, :include, :conditions
  def entities(options={})
    if self.use_free_search
      self.search_freetext(self.free_search_tokens, options)
    else
      scope = create_entity_scope(options)

      if has_custom_field_column?
        scope = scope.preload(:custom_values)
      end

      scope.all
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def entities_ids(options={})
    scope = create_entity_scope(options)
    scope.find_ids
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def search_freetext_count(tokens, options={})
    options[:all_words] = true unless options.key?(:all_words)
    tokens = [] << tokens unless tokens.is_a?(Array)

    token_clauses = statement_for_searching
    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

    scope = create_entity_scope(options)
    scope = scope.where([sql, * (tokens.collect{|i| "%#{i}%"} * token_clauses.size).sort])
    scope = scope.group(options[:group]) unless options[:group].nil?
    scope.limit(options[:limit] || 25).count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def search_freetext(tokens, options={})
    options[:all_words] = true unless options.key?(:all_words)
    tokens = [] << tokens unless tokens.is_a?(Array)

    token_clauses = statement_for_searching
    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

    scope = create_entity_scope(options)
    scope = scope.where([sql, * (tokens.collect{|i| "%#{i.downcase}%"} * token_clauses.size).sort])
    scope.limit(options[:limit] || 25).all
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def prepare_result(options={})
    include_all_entities = options.delete(:include_all_entities)
    entities = self.entities(options)

    prepared_result = ActiveSupport::OrderedHash.new
    if self.grouped?
      if self.group_by_column.is_a?(EasyQueryColumn)
        grouped_entities = entities.group_by{|i| self.group_by_column.value(i) }
      else
        grouped_entities = entities.group_by{|i| x = self.group_by_column.custom_value_of(i); (x.value if x).to_s }
      end

      counts = self.entity_count_by_group
      grouped_entities.each do |group, groups_entities|
        # sum
        sum = summarize_entities(groups_entities, group)
        prepared_result[group] = {:entities => groups_entities, :sums => sum, :count => (counts[group] || groups_entities.count) }
      end
    else
      prepared_result = {nil => {:entities => entities, :sums => summarize_entities(entities)}}
    end

    return prepared_result, entities if include_all_entities
    return prepared_result
  end

  def operators_for_select(filter_type)
    self.operators_by_filter_type[filter_type].collect {|o| [l(self.operators[o]), o] }
  end

  def from_params(params)
    return if params.nil?

    if params['set_filter'] == '1'
      self.filters = {}
      self.group_by = ''
    else
      self.filters = self.default_filter
      self.group_by = self.default_group_by
    end

    if params['fields'] && params['fields'].is_a?(Array)
      params['values'] ||= {}

      params['fields'].each do |field|
        self.add_filter(field, params['operators'][field], params['values'][field])
      end
    else
      self.available_filters.keys.each do |field|
        self.add_short_filter(field, params[field]) if params[field]
      end
    end

    self.group_by = params['group_by'] unless params['group_by'].blank?

    if params['easy_query'] && params['easy_query']['columns_to_export'] == 'all'
      self.column_names = available_columns.collect{|col| col.name.to_s}
    elsif params['easy_query'] && params['easy_query']['column_names'] && params['easy_query']['column_names'].is_a?(Array)
      if params['easy_query']['column_names'].first && params['easy_query']['column_names'].first.include?(',')
        self.column_names = params['easy_query']['column_names'].first.split(',')
      else
        self.column_names = params['easy_query']['column_names']
      end
    end

    self.sort_criteria = params['easy_query']['sort_criteria'] if params['easy_query'] && params['easy_query']['sort_criteria']

    if params['easy_query_q']
      self.use_free_search = true
      self.free_search_question = params['easy_query_q']
      self.free_search_question.strip!

      # extract tokens from the question
      # eg. hello "bye bye" => ["hello", "bye bye"]
      self.free_search_tokens = self.free_search_question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
      # tokens must be at least 2 characters long
      self.free_search_tokens = self.free_search_tokens.uniq.select {|w| w.length > 1 }
      self.free_search_tokens.slice! 5..-1 if self.free_search_tokens.size > 5
    end
  end

  def to_params
    easy_query_params = {:type => self.class.name, :fields => [], :operators => {}, :values => {}}
    easy_query_params[:easy_query] = { 'column_names' => (self.column_names || []).collect(&:to_s)}
    self.filters.each do |f, o|
      easy_query_params[:fields] << f
      easy_query_params[:operators][f] = o[:operator]
      easy_query_params[:values][f] = o[:values]
    end
    easy_query_params[:group_by] = self.group_by
    easy_query_params[:set_filter] = '1'

    return easy_query_params
  end

  def extended_period_options
    {}
  end

  protected

  def get_custom_sql_for_field(field, operator, value)
    nil
  end

  def statement_skip_fields
    []
  end

  def add_statement_sql_before_filters
    nil
  end

  def default_filter
    (@default_filter ||= (get_default_values_from_easy_settings('default_filters') || Hash.new)).dup
  end

  def default_group_by
    get_default_values_from_easy_settings('grouped_by') || ''
  end

  def sql_for_custom_field(field, operator, value, custom_field_id)
    operator = operator.to_s
    db_table = CustomValue.table_name
    db_field = 'value'
    db_entity = self.entity
    filter = self.available_filters[field]
    return nil unless filter
    if filter[:format] == 'user'
      if value.delete('me')
        value.push User.current.id.to_s
      end
    end
    not_in = nil
    if operator == '!'
      # Makes ! operator work for custom fields with multiple values
      operator = '='
      not_in = 'NOT'
    end
    customized_key = "id"
    customized_class = entity
    if field =~ /^(.+)\.cf_/
      assoc = $1
      customized_key = "#{assoc}_id"
      customized_class = entity.reflect_on_association(assoc.to_sym).klass.base_class rescue nil
      raise "Unknown Issue association #{assoc}" unless customized_class
    end
    where = sql_for_field(field, operator, value, db_table, db_field, true)
    if operator =~ /[<>]/
      where = "(#{where}) AND #{db_table}.#{db_field} <> ''"
    end
    "#{db_entity.table_name}.#{customized_key} #{not_in} IN (" +
      "SELECT #{customized_class.table_name}.id FROM #{customized_class.table_name}" +
      " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='#{customized_class}' AND #{db_table}.customized_id=#{customized_class.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id}" +
      " WHERE (#{where}) AND (#{filter[:field].visibility_by_project_condition}))"
  end

  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
    operator = operator.to_s
    value = value.to_a if value.is_a?(String)
    field_settings = self.available_filters[field]
    sql = ''

    if db_table.blank?
      full_db_field_name = db_field
    else
      full_db_field_name = "#{db_table}.#{db_field}"
    end

    # sometimes operator is not saved
    if operator.blank? && value.is_a?(Hash) && value.key?(:period)
      if value[:period].blank?
        operator = 'date_period_2'
      else
        operator = 'date_period_1'
      end
    end

    case operator
    when '='
      if value.any?
        case type_for(field)
        when :date, :date_past
          sql = date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), (Date.parse(value.first) rescue nil))
        when :integer
          sql = "#{full_db_field_name} = #{value.first.to_i}"
        when :float
          sql = "#{full_db_field_name} BETWEEN #{value.first.to_f - 1e-5} AND #{value.first.to_f + 1e-5}"
        else
          sql = "#{full_db_field_name} IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
          if value.size == 1 && value[0].blank?
            sql << " OR #{full_db_field_name} IS NULL"
          end
        end
      else
        # IN an empty set
        sql = '1=0'
      end
    when '!'
      if value.any?
        sql = "#{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
        if value.size == 1 && value[0].blank?
          sql << " OR #{full_db_field_name} IS NOT NULL"
        else
          sql << " OR #{full_db_field_name} IS NULL"
        end
      else
        # NOT IN an empty set
        sql = '1=1'
      end
    when '!*'
      sql = "#{full_db_field_name} IS NULL"
      sql << " OR #{full_db_field_name} = ''" if is_custom_filter
    when '*'
      sql = "#{full_db_field_name} IS NOT NULL"
      sql << " AND #{full_db_field_name} <> ''" if is_custom_filter
    when '>='
      if [:date, :date_past].include?(self.type_for(field))
        sql = self.date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), nil)
      else
        if is_custom_filter
          sql = "CAST(#{full_db_field_name} AS decimal(60,3)) >= #{value.first.to_f}"
        else
          sql = "#{full_db_field_name} >= #{value.first.to_f}"
        end
      end
    when '<='
      if [:date, :date_past].include?(self.type_for(field))
        sql = self.date_clause(db_table, db_field, nil, (Date.parse(value.first) rescue nil))
      else
        if is_custom_filter
          sql = "CAST(#{full_db_field_name} AS decimal(60,3)) <= #{value.first.to_f}"
        else
          sql = "#{full_db_field_name} <= #{value.first.to_f}"
        end
      end
    when '><'
      if [:date, :date_past].include?(self.type_for(field))
        sql = self.date_clause(db_table, db_field, (Date.parse(value[0]) rescue nil), (Date.parse(value[1]) rescue nil))
      else
        if is_custom_filter
          sql = "CAST(#{full_db_field_name} AS decimal(60,3)) BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
        else
          sql = "#{full_db_field_name} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
        end
      end
    when 'o'
      sql = "#{IssueStatus.table_name}.is_closed=#{self.connection.quoted_false}" if field == "status_id"
    when 'c'
      sql = "#{IssueStatus.table_name}.is_closed=#{self.connection.quoted_true}" if field == "status_id"
    when '><t-'
      # between today - n days and today
      sql = self.relative_date_clause(db_table, db_field, - value.first.to_i, 0)
    when '>t-'
      # >= today - n days
      sql = self.relative_date_clause(db_table, db_field, - value.first.to_i, nil)
    when '<t-'
      # <= today - n days
      sql = self.relative_date_clause(db_table, db_field, nil, - value.first.to_i)
    when 't-'
      # = n days in past
      sql = self.relative_date_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
    when '><t+'
      # between today and today + n days
      sql = self.relative_date_clause(db_table, db_field, 0, value.first.to_i)
    when '>t+'
      # >= today + n days
      sql = self.relative_date_clause(db_table, db_field, value.first.to_i, nil)
    when '<t+'
      # <= today + n days
      sql = self.relative_date_clause(db_table, db_field, nil, value.first.to_i)
    when 't+'
      # = today + n days
      sql = self.relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i)
    when 't'
      # = today
      sql = self.relative_date_clause(db_table, db_field, 0, 0)
    when 'w'
      # = this week
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = Date.today.cwday
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql = self.relative_date_clause(db_table, db_field, - days_ago, - days_ago + 6)
    when 'date_period_1'
      case value[:period].to_sym
      when :is_null
        sql = "(#{full_db_field_name} IS NULL OR #{full_db_field_name} = '')"
      when :is_not_null
        sql = "(#{full_db_field_name} IS NOT NULL AND #{full_db_field_name} <> '')"
      else
        period_dates = self.get_date_range('1', value[:period], value[:from], value[:to])
        sql = field_settings[:time_column] ?
          self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day)) :
          self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from]), (period_dates[:to].nil? ? nil : period_dates[:to]))
      end
    when 'date_period_2'
      period_dates = self.get_date_range('2', value[:period], value[:from], value[:to])
      sql = field_settings[:time_column] ?
        self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day)) :
        self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from]), (period_dates[:to].nil? ? nil : period_dates[:to]))
    when '~'
      sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    when '!~'
      sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    else
      raise "Unknown query operator #{operator}"
    end

    return sql
  end

  def add_custom_field_filter(field, assoc=nil)
    case field.field_format
    when 'text'
      options = { :type => :text, :order => 100 + field.position }
    when 'list'
      options = { :type => :list_optional, :values => field.possible_values, :order => 100 + field.position }
    when 'date'
      options = { :type => :date_period, :order => 100 + field.position, :time_column => false }
    when 'datetime'
      options = { :type => :date_period, :order => 100 + field.position, :time_column => true }
    when 'bool'
      options = { :type => :list, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], :order => 100 + field.position }
    when 'int'
      options = { :type => :integer, :order => 100 + field.position }
    when 'amount' 'float'
      options = { :type => :float, :order => 100 + field.position }
    when 'easy_computed_token'
      type = case field.settings['easy_computed_token_format']
      when 'int'
        :integer
      when 'float'
        :float
      else
        :string
      end
      options = { :type => type, :order => 100 + field.position }
    when 'user'
      if project
        values = field.possible_values_options(project)
      else
        values = User.non_system_flag.sorted.all.collect{|u| [u.name, u.id]}
      end
      if User.current.logged?
        values.unshift ["<< #{l(:label_me)} >>", 'me']
      end
      options = { :type => :list_optional, :values => values, :order => 100 + field.position}
    when 'version'
      return unless project
      values = field.possible_values_options(project)
      options = { :type => :list_optional, :values => values, :order => 100 + field.position}
    when 'easy_lookup'
      options = { :type => :easy_lookup, :entity_type => field.settings['entity_type'],
        :entity_attribute => field.settings['entity_attribute'], :order => 100 + field.position}
    else
      options = { :type => :string, :order => 100 + field.position }
    end

    filter_id = "cf_#{field.id}"
    filter_name = field.translated_name
    filter_group = l("field_#{entity.name.underscore}")+' '+l(:label_filter_group_custom_fields_suffix)
    if assoc.present?
      filter_id = "#{assoc}.#{filter_id}"
      filter_name = l("label_attribute_of_#{assoc}", :name => filter_name)
      filter_group = l("field_#{assoc}")+' '+l(:label_filter_group_custom_fields_suffix)
    end
    @available_filters[filter_id] = options.merge({
        :name => filter_name,
        :format => field.field_format,
        :field => field,
        :group => filter_group
      })
  end

  def add_custom_fields_filters(scope, assoc=nil)
    scope.visible.where(:is_filter => true).sorted.each do |field|
      add_custom_field_filter(field, assoc)
    end
  end

  def add_associations_custom_fields_filters(*associations)
    fields_by_class = CustomField.visible.where(:is_filter => true).group_by(&:class)
    associations.each do |assoc|
      association_klass = entity.reflect_on_association(assoc).klass
      fields_by_class.each do |field_class, fields|
        if field_class.customized_class <= association_klass
          fields.sort.each do |field|
            add_custom_field_filter(field, assoc)
          end
        end
      end
    end
  end

  # return type = :sql || :array
  def joins_for_order_statement(order_options, return_type = :sql)

    joins = []

    order_options.scan(/cf_\d+/).uniq.each do |name|
      column = available_columns.detect {|c| c.name.to_s == name}
      join = column && column.additional_joins(self.entity, return_type)
      if join
        joins += join
      end
    end if order_options

    case return_type
    when :sql
      joins.any? ? joins.join(' ') : nil
    when :array
      joins
    else
      raise ArgumentError, 'return_type has to be either :sql or :array'
    end
  end

  # Returns a SQL clause for a date or datetime field.
  def date_clause(table, field, from, to)
    s = []
    if from
      from_yesterday = from - 1
      from_yesterday_time = Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day)
      if self.class.default_timezone == :utc
        from_yesterday_time = from_yesterday_time.utc
      end
      s << ("#{table}.#{field} > '%s'" % [connection.quoted_date(from_yesterday_time.end_of_day)])
    end
    if to
      to_time = Time.local(to.year, to.month, to.day)
      if self.class.default_timezone == :utc
        to_time = to_time.utc
      end
      s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date(to_time.end_of_day)])
    end
    s.join(' AND ')
  end

  # Returns a SQL clause for a date or datetime field not in range.
  def reversed_date_clause(table, field, from, to)
    s = []
    if from
      from_yesterday = from - 1
      from_yesterday_time = Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day)
      if self.class.default_timezone == :utc
        from_yesterday_time = from_yesterday_time.utc
      end
      s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date(from_yesterday_time.end_of_day)])
    end
    if to
      to_time = Time.local(to.year, to.month, to.day)
      if self.class.default_timezone == :utc
        to_time = to_time.utc
      end
      s << ("#{table}.#{field} > '%s'" % [connection.quoted_date(to_time.end_of_day)])
    end
    if s.empty?
      ''
    else
      '('+s.join(' OR ')+')'
    end
  end

  # Returns a SQL clause for a date or datetime field using relative dates.
  def relative_date_clause(table, field, days_from, days_to)
    date_clause(table, field, (days_from ? Date.today + days_from : nil), (days_to ? Date.today + days_to : nil))
  end

  def statement_for_searching
    columns = self.searchable_columns

    token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ? )"}

    if !self.entity.reflect_on_association(:custom_values).nil?
      searchable_custom_field_ids = CustomField.where(:type => "#{self.entity}CustomField", :searchable => true).pluck(:id)
      if searchable_custom_field_ids.any?
        customized_type = "#{self.entity}CustomField".constantize.customized_class.name
        custom_field_sql = "#{self.entity.table_name}.id IN (SELECT customized_id FROM #{CustomValue.table_name}" +
          " WHERE customized_type='#{customized_type}' AND customized_id=#{self.entity.table_name}.id AND value LIKE ?" +
          " AND #{CustomValue.table_name}.custom_field_id IN (#{searchable_custom_field_ids.join(',')}))"
        token_clauses << custom_field_sql
      end
    end

    return token_clauses
  end

  def get_class_name
    self.class.name
  end

  protected

  def sql_time_diff(time1, time2, precision = :hour)
    case ActiveRecord::Base.connection.adapter_name.downcase.to_sym
    when :mysql
      "HOUR(TIMEDIFF(#{time1}, #{time2}))"
    when :mysql2
      "HOUR(TIMEDIFF(#{time1}, #{time2}))"
    when :postgresql
      "EXTRACT(epoch FROM (#{time2} - #{time1}) )/3600"
    end
  end

  private

  def entity_column_for(field)
    field_name = field.respond_to?(:name) ? field.name.to_s : field.to_s.split('.').last
    entity.columns.detect { |c| c.name.to_s == field_name }
  end

  def unique_entities(entities, distinct_columns)
    keys = []
    result = []
    entities.each do |e|
      key = []
      distinct_columns.each do |dc|
        value = if dc.respond_to?(:call)
          dc.call(e)
        elsif e.respond_to?(dc)
          e.send(dc)
        end
        key << value
      end
      next if keys.include?(key)
      result << e
      keys << key
    end

    result
  end

  def summarize_column(column, entities, group = nil)
    @cached_column_sums ||= {}
    if column.sumable_sql
      #group due to paging - if group is on multiple pages, it count only last page
      @cached_column_sums[column] ||= self.entity_sum_by_group(column)
      result = @cached_column_sums[column][group] || @cached_column_sums[column][group.to_s] || @cached_column_sums[column][BigDecimal.new(group.to_s)]
      result ||= @cached_column_sums[column][nil] if group.blank?
      result
    else
      if column.sumable_options.distinct_columns?
        unique_entities(entities, column.sumable_options.distinct_columns(:call)).sum{|i| column.value(i) || 0.0}
      else
        entities.sum{|i| column.value(i) || 0.0}
      end
    end
  end

  # return hash of sums columns for
  # * *top* - if query grouped
  # * *bottom* - extra row in list with sums of columns
  def summarize_entities(entities, group = nil)
    top, bottom = ActiveSupport::OrderedHash.new, ActiveSupport::OrderedHash.new
    self.sumable_columns.each do |column|
      if column.sumable_top? && self.grouped?
        top[column] = summarize_column(column, entities, group)
      end
      if column.sumable_bottom?
        bottom[column] = top[column] || summarize_column(column, entities, group)
      end
    end
    return {:top => top, :bottom => bottom}
  end

  def get_default_values_from_easy_settings(type)
    easy_setting = EasySetting.where(:name => "#{get_class_name.underscore}_#{type}", :project_id => nil).first
    default_value = easy_setting.value if easy_setting

    return default_value
  end

  def merge_scope(scope, options={})
    options ||= {}

    scope = scope.where(options[:where]) if options[:where]
    scope = scope.where(options[:conditions]) if options[:conditions]
    scope = scope.includes(options[:includes]) if options[:includes]
    scope = scope.joins(options[:joins]) if options[:joins]
    scope = scope.order(options[:order]) if options[:order]
    scope = scope.group(options[:group]) if options[:group]
    scope = scope.limit(options[:limit]) if options[:limit]
    scope = scope.offset(options[:offset]) if options[:offset]
    scope
  end

  def merge_options(options1, options2)
    options1.merge!(options2) do |key, oldval, newval|
      if newval.is_a?(Array) && oldval.is_a?(Array)
        oldval + newval
      elsif oldval.is_a?(String) && newval.is_a?(String)
        case key
        when :where
          oldval + ' AND ' + newval
        else
          newval
        end
      else
        newval
      end
    end
  end

end
