class EasyVersionQuery < EasyQuery
  include ProjectsHelper

  def available_filters
    return @available_filters unless @available_filters.blank?

    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_filters = {
      'status' => { :type => :list, :values => Version::VERSION_STATUSES.collect {|s| [l("version_status_#{s}"), s]}, :order => 1, :group => group},
      'name' => { :type => :text, :order => 2, :group => group},
      'effective_date' => { :type => :date_period, :order => 3, :group => group},
      'role_id' => { :type => :list, :order => 5, :values => Proc.new{Role.all.collect{|r| [r.name, r.id.to_s]}} , :group => group},
      'created_on' => { :type => :date_period, :order => 6, :group => group},
      'updated_on' => { :type => :date_period, :order => 7, :group => group},
      'sharing' => { :type => :list, :values => Version::VERSION_SHARINGS.collect {|s| [format_version_sharing(s), s]}, :order => 8, :group => group},
      'easy_version_category_id' => {:type => :list, :values => Proc.new{EasyVersionCategory.active.all.collect{|v| [v.name, v.id]}}, :order => 10, :group => group}
    }

    @available_filters['member_id'] = { :type => :list, :order => 4, :values => Proc.new do
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
      :group => group
    }

    if self.project
      @available_filters['xproject_id'] = {:type => :list, :values => Proc.new{projects_for_select(self.project.self_and_ancestors.visible.non_templates.order(:lft))}, :order => 13, :group => group}
    else
      @available_filters['project_id'] = {:type => :list, :values => Proc.new{projects_for_select(Project.visible.non_templates.order(:lft))}, :order => 13, :group => group}
    end

    add_custom_fields_filters(VersionCustomField)

    @available_filters
  end

  def easy_query_entity_controller
    self.project ? 'versions' : 'easy_versions'
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:status, :sortable => "#{Version.table_name}.status", :groupable => true),
        EasyQueryColumn.new(:name, :sortable => "#{Version.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:effective_date, :sortable => "#{Version.table_name}.effective_date", :groupable => true),
        EasyQueryColumn.new(:description),
        EasyQueryColumn.new(:easy_version_category, :groupable => true, :sortable => "#{EasyVersionCategory.table_name}.name"),
        EasyQueryColumn.new(:sharing, :sortable => "#{Version.table_name}.sharing", :groupable => true),
        EasyQueryColumn.new(:created_on, :sortable => "#{Version.table_name}.created_on", :groupable => true),
        EasyQueryColumn.new(:updated_on, :sortable => "#{Version.table_name}.updated_on", :groupable => true),
        EasyQueryColumn.new(:completed_percent, :caption => :field_completed_percent)
      ]
      @available_columns += VersionCustomField.all.collect {|cf| EasyQueryCustomFieldColumn.new(cf)}
      @available_columns_added = true
    end
    @available_columns
  end

  def default_find_include
    [:project, :easy_version_category]
  end

  def default_sort_criteria
    ['project', 'name']
  end

  def entity
    Version
  end

  def entity_scope
    self.project.nil? ? Version.visible : self.project.shared_versions
  end

  def extended_period_options
    {
      :extended_options => [:to_today, :is_null, :is_not_null],
      :option_limit => {
        :after_due_date => ['effective_date'],
        :next_week => ['effective_date'],
        :tomorrow => ['effective_date'],
        :next_5_days => ['effective_date'],
        :next_7_days => ['effective_date'],
        :next_10_days => ['effective_date'],
        :next_30_days => ['effective_date'],
        :next_90_days => ['effective_date'],
        :next_month => ['effective_date'],
        :next_year => ['effective_date']
      }
    }
  end

  protected

  def statement_skip_fields
    ['member_id', 'role_id']
  end

  def add_statement_sql_before_filters
    my_fields = ['member_id', 'role_id'] & filters.keys

    unless my_fields.blank?
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

      sql = [sql_member_id, sql_role_id].compact.join(' AND ')

      return sql
    end
  end

  def sql_for_xproject_id_field(field, operator, v)
    db_table = self.entity.table_name
    db_field = 'project_id'
    returned_sql_for_field = self.sql_for_field(db_field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

end
