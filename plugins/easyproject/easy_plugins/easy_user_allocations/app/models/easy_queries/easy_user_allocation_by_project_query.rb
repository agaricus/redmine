class EasyUserAllocationByProjectQuery < EasyUserAllocationQuery

  def query_after_initialize
    super
    self.easy_query_entity_action = 'by_project'
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    @available_filters = basic_filters.dup
    @available_filters.merge!(project_filters)
    @available_filters.merge!(user_filters)

    return @available_filters
  end

  def project_filters
    return @project_filters unless @project_filters.blank?
    @project_filters = {}
    EasyProjectQuery.new.available_filters.each do |name, f|
      @project_filters["project_#{name}"] = f
      @project_filters["project_#{name}"][:name] ||= I18n.translate("field_#{name.gsub(/_id$/, '')}")
    end
    @project_filters
  end

  def project_query
    query = EasyProjectQuery.new
    filters.each do |name, f|
      if name =~ /^project_/
        query.add_filter name.gsub(/^project_/, ''), f[:operator], f[:values]
      end
    end
    query
  end

  def data_by_project(from, to)
    users = user_query.entities
    allocations = {}
    project_query.entities(:limit => 70).each do |project|
      users_allocations = project.easy_user_allocations.
        select('*, SUM(hours) as hours').
        group(:user_id, :date).
        where(:date => from..to, :user_id => users).
        all.group_by(&:user_id)

      user_data = {}
      users.each do |user|
        if users_allocations.has_key?(user.id)
          user_data[user] = users_allocations[user.id]
        end
      end
      allocations[project] = user_data
    end
    allocations
  end

  def default_filter
    {
      'range'=>{:operator=>'date_period_1', :values => HashWithIndifferentAccess.new({:period => 'next_90_days', :from => '', :to => ''})},
      'issue_status_id' => {:operator => 'o', :values => ['1']},
      'issue_is_planned' => {:operator => '=', :values => ['0']},
      'user_status'=>{:operator=>'=', :values => [User::STATUS_ACTIVE.to_s]}
    }
  end

end
