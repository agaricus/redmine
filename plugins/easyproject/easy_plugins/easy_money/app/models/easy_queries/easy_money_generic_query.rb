class EasyMoneyGenericQuery < EasyQuery

  attr_accessor :entity_to_statement

  def self.permission_view_entities
    :view_easy_money
  end

  def available_filters
    return @available_filters unless @available_filters.blank?
    all_projects = Project.visible.non_templates.has_module(:easy_money)
    group = l("label_filter_group_#{self.class.name.underscore}")
    @available_filters = {
      'spent_on' => { :type => :date_period, :order => 3, :group => group },
      'name' => { :type => :string, :order => 4, :group => group },
      'description' => { :type => :text, :order => 5, :group => group },
      'price1' => { :type => :float, :order => 6, :group => group },
      'price2' => { :type => :float, :order => 7, :group => group },
      'vat' => { :type => :float, :order => 8, :group => group},
      'version_id' => { :type => :list_optional, :order => 9, :values => Version.visible.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s] }, :group => group}
    }

    if project
      unless project.leaf?
        subprojects = project.easy_is_easy_template ? project.descendants.visible.templates : project.descendants.visible.non_templates
        unless subprojects.empty?
          @available_filters['subproject_id'] = { :type => :list_subprojects, :order => 2, :values => subprojects.collect{|s| [s.name, s.id.to_s] } }
        end
      end
    else
      if all_projects.any?
        @available_filters['project'] = { :type => :list, :order => 1, :values => self.projects_for_select(all_projects)}
        @available_filters['parent_id'] = { :type => :list, :order => 2, :values => self.projects_for_select(all_projects)}
        @available_filters['main_project'] = { :type => :list, :order => 3, :values => self.projects_for_select(all_projects.roots, false)}
      end
    end

    if self.entity_custom_field
      add_custom_fields_filters(self.entity_custom_field)
    end

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:project, :groupable => true, :polymorphic => {:name => :entity, :type=>'Project'}),
        EasyQueryColumn.new(:main_project, :groupable => true),
        EasyQueryColumn.new(:issue),
        EasyQueryColumn.new(:version),
        EasyQueryColumn.new(:spent_on, :sortable => "#{self.entity.table_name}.spent_on", :groupable => true),
        EasyQueryColumn.new(:name, :sortable => "#{self.entity.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:description, :sortable => "#{self.entity.table_name}.description"),
        EasyQueryColumn.new(:price1, :sortable => "#{self.entity.table_name}.price1", :sumable => :top),
        EasyQueryColumn.new(:price2, :sortable => "#{self.entity.table_name}.price2", :sumable => :top),
        EasyQueryColumn.new(:vat, :sortable => "#{self.entity.table_name}.vat", :groupable => true),
      ]

      if self.entity_custom_field
        @available_columns += self.entity_custom_field.all.collect{|cf| EasyQueryCustomFieldColumn.new(cf)}
      end

      @available_columns_added = true
    end
    @available_columns
  end

  def additional_statement
    unless @additional_statement_added
      sql = project_statement
      @additional_statement = sql unless sql.blank?
      @additional_statement_added = true
    end
    @additional_statement
  end

  def searchable_columns
    return ["#{self.entity.table_name}.name"]
  end

  def entity_custom_field
  end

  def statement_skip_fields
    ['subproject_id']
  end

  def default_find_joins
    joins = super
    joins << "LEFT OUTER JOIN #{Project.table_name} joined_project ON  #{self.entity.table_name}.entity_id = joined_project.id AND #{self.entity.table_name}.entity_type = 'Project'"
  end

  def project_statement(project_table='joined_project')
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
      elsif self.project.easy_money_settings.include_childs?
        if self.project.easy_is_easy_template
          ids += self.project.descendants.templates.has_module(:easy_money).pluck(:id)
        else
          ids += self.project.descendants.non_templates.has_module(:easy_money).pluck(:id)
        end
      end
      project_clauses << "(#{project_table}.id IN (%s) OR #{project_table}.id IS NULL)" % ids.join(',')
    elsif self.project
      project_clauses << "(#{project_table}.id = %d OR #{project_table}.id IS NULL)" % self.project.id
    elsif !self.project
      project_clauses << "(#{project_table}.easy_is_easy_template=#{self.connection.quoted_false} OR #{project_table}.easy_is_easy_template IS NULL)"
    end
    project_clauses.any? ? project_clauses.join(' AND ') : nil
  end

  def project_statement_ids
    ids = []
    if self.project && !self.project.descendants.active.empty?
      ids += [self.project.id]
      if self.has_filter?('subproject_id')
        case self.operator_for('subproject_id')
        when '='
          # include the selected subprojects
          ids = self.values_for('subproject_id').each(&:to_i)
        when '!*'
          # main project only
        else
          # all subprojects
          ids += self.project.descendants.pluck(:id)
        end
      elsif self.project.easy_money_settings.include_childs?
        if self.project.easy_is_easy_template
          ids += self.project.descendants.templates.has_module(:easy_money).pluck(:id)
        else
          ids += self.project.descendants.non_templates.has_module(:easy_money).pluck(:id)
        end
      end
    elsif self.project
      ids += [self.project.id]
    elsif !self.project
      #project_clauses << "#{Project.table_name}.easy_is_easy_template=#{self.connection.quoted_false}"
    end
    ids
  end

  def add_statement_sql_before_filters
    where = []
    if self.entity_to_statement
      case self.entity_to_statement.class.name
      when 'Project'
        sql_where = []

        if project && project.easy_money_settings.include_childs?
          sql_where << "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Project' AND p.lft >= #{self.entity_to_statement.lft} AND p.rgt <= #{self.entity_to_statement.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
          sql_where << "EXISTS (
SELECT i.id
FROM #{Issue.table_name} i
INNER JOIN #{Project.table_name} p ON p.id = i.project_id
WHERE i.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Issue' AND p.lft >= #{self.entity_to_statement.lft} AND p.rgt <= #{self.entity_to_statement.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
        else
          sql_where << "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Project' AND p.id = #{self.entity_to_statement.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
          sql_where << "EXISTS (
SELECT i.id
FROM #{Issue.table_name} i
INNER JOIN #{Project.table_name} p ON p.id = i.project_id
WHERE i.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Issue' AND p.id = #{self.entity_to_statement.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
        end

        sql_where << "EXISTS (
SELECT v.id
FROM #{Version.table_name} v
WHERE v.id = #{self.entity.table_name}.entity_id
AND #{self.entity.table_name}.entity_type = 'Version' AND v.project_id = #{self.entity_to_statement.id})"

        where << '(' + sql_where.join(' OR ') + ')'
      when 'Issue'
        where << "EXISTS (SELECT i.id FROM #{Issue.table_name} i WHERE i.id = #{self.entity.table_name}.entity_id AND #{self.entity.table_name}.entity_type = 'Issue' AND i.root_id = #{self.entity_to_statement.root_id} AND i.lft >= #{self.entity_to_statement.lft} AND i.rgt <= #{self.entity_to_statement.rgt})"
      when 'Version'
        where <<  "#{self.entity.table_name}.entity_type = 'Version' AND #{self.entity.table_name}.entity_id = #{self.entity_to_statement.id}"
      else
        where << "#{self.entity.table_name}.entity_type = '#{connection.quote_string(self.entity_to_statement.class.name)}' AND #{self.entity.table_name}.entity_id = #{self.entity_to_statement.id}"
      end
    end
    where.join(' AND ') unless where.blank?
  end

  def sql_for_project_field(field, operator, value)
    sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
    "CASE #{self.entity.table_name}.entity_type
      WHEN 'Project' THEN EXISTS(SELECT p1.id FROM #{Project.table_name} p1 WHERE #{self.entity.table_name}.entity_id = p1.id AND p1.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Issue' THEN EXISTS(SELECT i1.id FROM #{Issue.table_name} i1 LEFT OUTER JOIN #{Project.table_name} p1 ON i1.project_id = p1.id WHERE #{self.entity.table_name}.entity_id = i1.id AND i1.project_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Version' THEN EXISTS(SELECT v1.id FROM #{Version.table_name} v1 WHERE #{self.entity.table_name}.entity_id = v1.id AND v1.project_id #{sql_value})
    END"
  end

  def sql_for_main_project_field(field, operator, value)
    sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
    "CASE #{self.entity.table_name}.entity_type
      WHEN 'Project' THEN EXISTS(SELECT p1.id FROM #{Project.table_name} p1 INNER JOIN #{Project.table_name} p2 ON p2.lft >= p1.lft AND p2.rgt <= p1.rgt WHERE #{self.entity.table_name}.entity_id = p2.id AND p1.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Issue' THEN EXISTS(SELECT i1.id FROM #{Issue.table_name} i1 INNER JOIN #{Project.table_name} p1 ON p1.id = i1.project_id INNER JOIN #{Project.table_name} p2 ON p2.lft <= p1.lft AND p2.rgt >= p1.rgt AND p2.parent_id IS NULL WHERE #{self.entity.table_name}.entity_id = i1.id AND p2.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Version' THEN EXISTS(SELECT v1.id FROM #{Version.table_name} v1 INNER JOIN #{Project.table_name} p1 ON p1.id = v1.project_id INNER JOIN #{Project.table_name} p2 ON p2.lft <= p1.lft AND p2.rgt >= p1.rgt AND p2.parent_id IS NULL WHERE #{self.entity.table_name}.entity_id = v1.id AND p2.id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
    END"
  end

  def sql_for_parent_id_field(field, operator, value)
    sql_value = "#{operator == '=' ? 'IN' : 'NOT IN'} (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
    "CASE #{self.entity.table_name}.entity_type
      WHEN 'Project' THEN EXISTS(SELECT p1.id FROM #{Project.table_name} p1 WHERE #{self.entity.table_name}.entity_id = p1.id AND p1.parent_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Issue' THEN EXISTS(SELECT i1.id FROM #{Issue.table_name} i1 INNER JOIN #{Project.table_name} p1 ON p1.id = i1.project_id WHERE #{self.entity.table_name}.entity_id = i1.id AND p1.parent_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
      WHEN 'Version' THEN EXISTS(SELECT v1.id FROM #{Version.table_name} v1 INNER JOIN #{Project.table_name} p1 ON p1.id = v1.project_id WHERE #{self.entity.table_name}.entity_id = v1.id AND p1.parent_id #{sql_value} AND p1.status <> #{Project::STATUS_ARCHIVED})
    END"
  end

end
