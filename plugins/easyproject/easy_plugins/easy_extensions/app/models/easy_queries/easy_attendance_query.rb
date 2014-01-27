class EasyAttendanceQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_attendances
  end

  def query_after_initialize
    super
    self.additional_statement = "#{EasyAttendance.table_name}.user_id = #{User.current.id}" unless  User.current.allowed_to?(:view_easy_attendance_other_users, nil, :global => true)
  end

  def available_filters
    return @available_filters unless @available_filters.blank?
    @available_filters = {
      'arrival' => { :type => :date_period, :time_column => true, :order => 1, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'departure' => { :type => :date_period, :time_column => true, :order => 2, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'easy_attendance_activity_id' => {:type => :list, :order => 4, :values => Proc.new{EasyAttendanceActivity.sorted.collect{|i| [i.name, i.id]}}, :group => l("label_filter_group_#{self.class.name.underscore}")}
    }

    if  User.current.allowed_to?(:view_easy_attendance_other_users, nil, :global => true)
      @available_filters['user_id'] = { :type => :list_optional, :order => 5, :values => Proc.new do
          assigned_to_values = Array.new
          assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
          assigned_to_values += User.active.non_system_flag.easy_type_internal.sorted.collect{|s| [s.name, s.id.to_s] }
        end,
        :group => l("label_filter_group_#{self.class.name.underscore}")
      }
      @available_filters['group_id'] = {:type => :list, :order => 15, :values => Proc.new{Group.active.non_system_flag.sorted.collect{|i| [i.name, i.id]}}, :group => l("label_filter_group_#{self.class.name.underscore}")}
    end

    if User.current.allowed_to?(:view_easy_attendances_extra_info, nil, :global => true)
      @available_filters['arrival_user_ip'] = {:type => :string, :order => 9, :group => l("label_filter_group_#{self.class.name.underscore}")}
      @available_filters['departure_user_ip'] = {:type => :string, :order => 10, :group => l("label_filter_group_#{self.class.name.underscore}")}
    end


    return @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:arrival, :sortable => "#{EasyAttendance.table_name}.arrival"),
        EasyQueryColumn.new(:departure, :sortable => "#{EasyAttendance.table_name}.departure"),
        EasyQueryColumn.new(:spent_time, :caption => :label_easy_attendance_spent_time, :sumable => :both, :sumable_sql => self.sql_time_diff("#{EasyAttendance.quoted_table_name}.departure", "#{EasyAttendance.quoted_table_name}.arrival") ),
        EasyQueryColumn.new(:working_time, :caption => :label_working_time, :sumable => :both, :disable_header_sum => true, :sumable_sql => false, :sumable_options => {:distinct_columns => [["#{User.table_name}.id", lambda{|e| e.user}], ["CAST( #{EasyAttendance.table_name}.arrival AS date)", lambda{|e| e.start_date}]]}),
        EasyQueryColumn.new(:easy_attendance_activity, :groupable => true, :sortable => "#{EasyAttendanceActivity.table_name}.name"),
        EasyQueryColumn.new(:description),
        EasyQueryColumn.new(:user, :groupable => true, :sortable => ["#{User.table_name}.lastname", "#{User.table_name}.firstname", "#{User.table_name}.id"])
      ]
      if User.current.allowed_to?(:view_easy_attendances_extra_info, nil, :global => true)
        @available_columns << EasyQueryColumn.new(:arrival_user_ip, :sortable => "#{self.entity.table_name}.arrival_user_ip")
        @available_columns << EasyQueryColumn.new(:departure_user_ip, :sortable => "#{self.entity.table_name}.departure_user_ip")
      end

      @available_columns << EasyQueryColumn.new(:created_at, :sortable => "#{EasyAttendance.table_name}.created_at")
      @available_columns << EasyQueryColumn.new(:updated_at, :sortable => "#{EasyAttendance.table_name}.updated_at")

      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    EasyAttendance
  end

  def default_find_include
    [:easy_attendance_activity, :user]
  end

  def default_sort_criteria
    [['arrival', 'desc']]
  end

  def columns_with_me
    super + ['user_id']
  end

  def extended_period_options
    {
      :extended_options => [:to_today, :next_week, :tomorrow, :next_7_days, :next_30_days, :next_90_days, :next_month, :next_year]
    }
  end

  protected

  def statement_skip_fields
    ['group_id']
  end

  def add_statement_sql_before_filters
    my_fields = statement_skip_fields & filters.keys

    unless my_fields.blank?
      values = values_for('group_id').join(',')
      if values.present?
        sql = "#{EasyAttendance.table_name}.user_id IN (SELECT u.id FROM #{User.table_name} u INNER JOIN groups_users gu ON u.id = gu.user_id WHERE gu.group_id #{operator_for('group_id') == '=' ? 'IN' : 'NOT IN'} (#{values}))"

        return sql
      end
    end
  end

end
