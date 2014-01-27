class EasyUserAllocationQuery < EasyQuery

  validate :validate_range

  def self.permission_view_entities
    :view_easy_user_allocations
  end

  def columns_with_me
    super + ['user_id']
  end

  def query_after_initialize
    super
    self.display_filter_columns_on_edit = false
    self.display_filter_group_by_on_edit = false
    self.display_filter_sort_on_edit = false
    self.display_filter_group_by_on_index = false
    self.display_filter_fullscreen_button = false
    self.easy_query_entity_controller = 'user_allocation_gantt'
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    @available_filters = basic_filters.dup
    @available_filters.merge!(issue_filters)
    @available_filters.merge!(user_filters)

    return @available_filters
  end

  def basic_filters
    watcher_values = User.active.collect{|u| [u.name, u.id.to_s]}.sort
    @basic_filters ||= {
      'range' => { :type => :date_period, :time_column => false, :order => 1, :name => l(:label_user_allocation_gantt_range), :group => l("label_filter_group_easy_user_allocation_query") }
    }
  end

  def issue_filters
    return @issue_filters unless @issue_filters.blank?
    @issue_filters = {}
    EasyIssueQuery.new.available_filters.each do |name, f|
      unless %w(created_on due_date updated_on).include?(name)
        @issue_filters["issue_#{name}"] = f
        @issue_filters["issue_#{name}"][:name] ||= I18n.translate("field_#{name.gsub(/_id$/, '')}")
      end
    end
    @issue_filters
  end

  def user_filters
    return @user_filters unless @user_filters.blank?
    @user_filters = {}
    EasyUserQuery.new.available_filters.each do |name, f|
      @user_filters["user_#{name}"] = f
      @user_filters["user_#{name}"][:name] ||= I18n.translate("field_#{name.gsub(/_id$/, '')}")
    end
    @user_filters["user_id"] = {
      :type => :list_optional,
      :order => 5,
      :values => (User.current.logged? ? [["<< #{l(:label_me)} >>", 'me']] : []) + User.active.non_system_flag.easy_type_internal.sorted.collect{|u| [u.name, u.id.to_s]},
      :name => l(:label_user_allocation_gantt_user_selection),
      :group => l("label_filter_group_easy_user_query")
    }
    @user_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true)
      ]
      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    Issue
  end

  def issues(from, to)
    issue_query = EasyIssueQuery.new
    issue_query.project = project
    filters.each do |name, f|
      if name =~ /^issue_/
        issue_query.add_filter name.gsub(/^issue_/, ''), f[:operator], f[:values]
      end
    end
    issue_query.additional_statement ||= ''
    issue_query.additional_statement << ' AND ' unless issue_query.additional_statement.blank?
    issue_query.additional_statement << "#{Issue.table_name}.assigned_to_id IS NULL AND "
    issue_query.additional_statement << "#{Issue.table_name}.start_date >= '#{from}' AND "
    issue_query.additional_statement << "#{Issue.table_name}.due_date <= '#{to}' AND "
    issue_query.additional_statement << "#{Issue.table_name}.estimated_hours IS NOT NULL AND "
    issue_query.additional_statement << "#{Project.table_name}.easy_is_easy_template = #{Project.connection.quoted_false}"
    issue_query.entities
  end

  def allocated_issues_ids(from, to, users=[])
    users ||= self.users
    issue_query = EasyIssueQuery.new
    issue_query.project = project
    issue_query.filters = {}
    filters.each do |name, f|
      if name =~ /^issue_/
        issue_query.add_filter name.gsub(/^issue_/, ''), f[:operator], f[:values]
      end
    end
    issue_query.additional_statement ||= ''
    issue_query.additional_statement << ' AND ' unless issue_query.additional_statement.blank?
    issue_query.additional_statement << "#{Issue.table_name}.assigned_to_id " << (users.any? ? "IN (#{users.collect(&:id).join(',')}) AND " : 'IS NULL AND ')
    issue_query.additional_statement << "#{Issue.table_name}.due_date <= '#{to}' AND "
    issue_query.additional_statement << "#{Issue.table_name}.due_date >= '#{from}'"
    issue_query.entities_ids
  end

  def user_query
    query = EasyUserQuery.new
    query.filters = {}
    filters.each do |name, f|
      if name =~ /^user_/
        query.add_filter name.gsub(/^user_/, ''), f[:operator], f[:values]
        query.add_filter 'easy_user_type', '=', User::EASY_USER_TYPE_INTERNAL.to_s
        query.add_filter 'easy_system_flag', '=', '0'
        if name == 'user_id'
          query.add_additional_statement(sql_for_field('id', f[:operator], f[:values].map{|v| v == 'me' ? User.current.id.to_s : v}, User.table_name, 'id'))
        end
      end
    end
    if self.project
      user_ids = project.users.pluck(:id)
      query.add_additional_statement(User.arel_table[:id].in(user_ids).to_sql)
    end
    query
  end

  def users
    user_query = self.user_query
    if !User.current.allowed_to_globally?(:view_easy_user_allocations, {}) && User.current.allowed_to_globally?(:view_my_easy_user_allocations, {})
      user_query.add_additional_statement("#{User.table_name}.id = #{User.current.id}")
    end
    user_query.entities(:order => User.fields_for_order_statement.join(', '))
  end

  def entity_scope
    Issue.visible
  end

  def extended_period_options
    {
      :option_limit => {
        :next_week => ['range'],
        :tomorrow => ['range'],
        :next_7_days => ['range'],
        :next_30_days => ['range'],
        :next_90_days => ['range'],
        :next_month => ['range'],
        :next_year => ['range']
      },
      :disabled_values => ['all']
    }
  end

  protected

  def validate_range
    range_valid = true
    case operator_for('range')
    when "date_period_1"
      range_valid = false if !values_for('range').is_a?(Hash) || values_for('range')[:period].blank?
    when "date_period_2"
      if (rng_from = values_for('range')[:from]).blank? || (rng_to = values_for('range')[:to]).blank?
        range_valid = false
      else
        begin
          if (Date.parse(rng_to) - Date.parse(rng_from)).to_i > 366
            errors.add(:base, "#{label_for('range')} #{l('resalloc.error_date_range_too_long')}")
          end
        rescue
          add_filter_error('range', :invalid) unless range_valid
        end
      end
    else
      range_valid = false
    end
    add_filter_error('range', :invalid) unless range_valid
  end
end
