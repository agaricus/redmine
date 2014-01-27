class EasyProjectQuery < EasyQuery

  def self.entity_css_classes(project, options={})
    project.css_classes(project.easy_level)
  end

  def self.permission_view_entities
    :view_project
  end

  def query_after_initialize
    super
    self.additional_statement = Project.allowed_to_condition(User.current, :view_project)
  end

  def available_filters
    return @available_filters unless @available_filters.blank?
    @available_filters = {
      'parent_id' => {:type => :list, :order => 1, :values => Proc.new{projects_for_select(Project.non_templates.visible.select([:id, :name, :easy_level, :lft, :rgt]).all)}, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'role_id' => { :type => :list, :order => 6, :values => Proc.new{Role.all.collect{|r| [r.name, r.id.to_s]}} , :group => l("label_filter_group_#{self.class.name.underscore}")},
      'name' => { :type => :text, :order => 8, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'status' => { :type => :list, :order => 9, :values => [[l(:project_status_planned), Project::STATUS_PLANNED.to_s], [l(:project_status_active), Project::STATUS_ACTIVE.to_s], [l(:project_status_closed), Project::STATUS_CLOSED.to_s]], :group => l("label_filter_group_#{self.class.name.underscore}")},
      'favorited' => { :type => :list, :order => 10, :values => [[l(:general_text_yes), '1']], :group => l("label_filter_group_#{self.class.name.underscore}")},
      'created_on' => { :type => :date_period, :order => 11, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'updated_on' => { :type => :date_period, :order => 12, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'easy_start_date' => { :type => :date_period, :order => 13, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'easy_due_date' => { :type => :date_period, :order => 14, :group => l("label_filter_group_#{self.class.name.underscore}") }
    }

    add_custom_fields_filters(ProjectCustomField)

    @available_filters['member_id'] = { :type => :list, :order => 5, :values => Proc.new do
        user_values = []
        user_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
        user_values += User.active.non_system_flag.sorted.collect{|s| [s.name, s.id.to_s] }
    #    if User.current.admin?
    #      user_values += User.active.sort_by(&:name).collect{|s| [s.name, s.id.to_s] }
    #    else
    #      user_values += User.current.projects.collect(&:users).flatten.uniq.sort_by(&:name).collect{|s| [s.name, s.id.to_s] }
    #    end
        user_values
      end,
      :group => l("label_filter_group_#{self.class.name.underscore}")
    }

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      if User.current.in_mobile_view?
        @available_columns = [
          EasyQueryColumn.new(:name, :sortable => "#{Project.table_name}.name")
        ]
      else
        @available_columns = [
          EasyQueryColumn.new(:name, :sortable => "#{Project.table_name}.name"),
          EasyQueryColumn.new(:parent),
          EasyQueryColumn.new(:root),
          EasyQueryColumn.new(:description, :sortable => "#{Project.table_name}.description"),
          EasyQueryColumn.new(:status),
          EasyQueryColumn.new(:author, :groupable => true, :sortable => User.fields_for_order_statement('authors')),
          EasyQueryColumn.new(:users, :caption => :field_member),
          EasyQueryColumn.new(:start_date),
          EasyQueryColumn.new(:due_date),
          EasyQueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on", :default_order => 'desc'),
          EasyQueryColumn.new(:sum_estimated_hours)
        ]

        if User.current.allowed_to?(:view_time_entries, project)
          @available_columns += [
            EasyQueryColumn.new(:sum_of_timeentries),
            EasyQueryColumn.new(:remaining_timeentries)
          ]
        end

        @available_columns += [
          EasyQueryColumn.new(:completed_percent)
        ]
        @available_columns += ProjectCustomField.all.collect {|cf| EasyQueryCustomFieldColumn.new(cf)}
      end
      @available_columns_added = true
    end
    @available_columns
  end

  def searchable_columns
    return ["#{Project.table_name}.name"]
  end

  def entity
    Project
  end

  def columns_with_me
    super + ['member_id']
  end

  def extended_period_options
    {
      :extended_options => [:to_today],
      :option_limit => {
        :is_null => ['easy_due_date', 'easy_start_date'],
        :is_not_null => ['easy_due_date', 'easy_start_date'],
        :after_due_date => ['easy_due_date'],
        :next_week => ['easy_due_date'],
        :tomorrow => ['easy_due_date'],
        :next_5_days => ['easy_due_date'],
        :next_7_days => ['easy_due_date'],
        :next_10_days => ['easy_due_date'],
        :next_30_days => ['easy_due_date'],
        :next_90_days => ['easy_due_date'],
        :next_month => ['easy_due_date'],
        :next_year => ['easy_due_date']
      }
    }
  end

  def default_sort_criteria
    [['lft', 'asc']]
  end

  def roots(options={})
    projects = Project.arel_table
    children = Arel::Table.new(:projects, :as => :children)
    children_statement = statement.gsub('projects.', 'children.')
    children_statement.gsub!(/FROM projects /i, 'FROM projects AS children ')

    join_sources = projects.join(children, Arel::Nodes::OuterJoin).on(
      projects[:lft].lteq(children[:lft]).and(
        children[:parent_id].not_eq(nil).and(
          projects[:rgt].gteq(children[:rgt])
        )
      )
    ).join_sources

    root_info = merge_scope(Project, options)
      .select('projects.id AS root_id, Count(children.id) AS children_count')
      .joins(join_sources)
      .where("( (#{statement}) OR (#{children_statement}) ) AND projects.parent_id IS NULL")
      .reorder(:'projects.lft')
      .group('projects.id').all

    return Hash[root_info.collect{|r| [r.root_id.to_i, r.children_count.to_i]}], Project.where(:id => root_info.collect(&:root_id)).reorder(:'projects.lft').all
  end

  def sql_for_favorited_field(field, operator, value)
    "EXISTS (SELECT * FROM favorite_projects WHERE favorite_projects.user_id = #{User.current.id} AND favorite_projects.project_id = projects.id)"
  end

  def only_favorited?
    filters.include?('favorited')
  end

  protected

  def statement_skip_fields
    ['member_id', 'role_id','parent_id']
  end

  def add_statement_sql_before_filters
    my_fields = ['member_id', 'role_id', 'parent_id'] & filters.keys

    unless my_fields.blank?
      if my_fields.include?('parent_id')
        parent_id_where = Array.new
        op_not = (operator_for('parent_id') == '!')
        Project.find(values_for('parent_id')).each do |p|
          if op_not
            parent_id_where << "#{Project.table_name}.id NOT IN (SELECT p_parent_id.id FROM #{Project.table_name} p_parent_id WHERE p_parent_id.lft >= #{p.lft} AND p_parent_id.rgt <= #{p.rgt})"
          else
            parent_id_where << "#{Project.table_name}.id IN (SELECT p_parent_id.id FROM #{Project.table_name} p_parent_id WHERE p_parent_id.lft >= #{p.lft} AND p_parent_id.rgt <= #{p.rgt})"
          end
        end

        if op_not
          sql_parent_id = parent_id_where.join(' AND ')
        else
          sql_parent_id = parent_id_where.join(' OR ')
        end
        sql_parent_id = "(#{sql_parent_id})"
      end

      if my_fields.include?('member_id')
        mv = values_for('member_id').dup
        mv.push(User.current.logged? ? User.current.id.to_s : '0') if mv.delete('me')
        sql_member_id = "#{Project.table_name}.id #{operator_for('member_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 WHERE "
        sql_member_id << sql_for_field('member_id', '=', mv, 'pm1', 'user_id', true)
        sql_member_id << ')'

        if my_fields.include?('role_id')
          sql_member_id << " AND #{Project.table_name}.id #{operator_for('role_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 INNER JOIN #{MemberRole.table_name} pmr1 ON pmr1.member_id = pm1.id WHERE "
          sql_member_id << sql_for_field('member_id', '=', mv, 'pm1', 'user_id', true)
          sql_member_id << (' AND ' + sql_for_field('role_id', '=', values_for('role_id').dup, 'pmr1', 'role_id', true))
          sql_member_id << ')'
        end
      elsif my_fields.include?('role_id')
        sql_role_id = "#{Project.table_name}.id #{operator_for('role_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 INNER JOIN #{MemberRole.table_name} pmr1 ON pmr1.member_id = pm1.id WHERE "
        sql_role_id << sql_for_field('role_id', '=', values_for('role_id').dup, 'pmr1', 'role_id', true)
        sql_role_id << ')'
      end

      sql = [sql_parent_id, sql_member_id, sql_role_id].compact.join(' AND ')

      return sql
    end
  end

  def joins_for_order_statement(order_options, return_type = :sql)
    joins = []

    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{Project.table_name}.author_id"
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

end
