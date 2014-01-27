class EasyUserQuery < EasyQuery

  def available_filters
    return @available_filters unless @available_filters.blank?
    group = l("label_filter_group_#{self.class.name.underscore}")

    user_count_by_status = User.count(:group => 'status').to_hash
    @available_filters = {
      'status' => { :type => :list, :order => 1, :values => [
          ["#{l(:status_active)} (#{user_count_by_status[1].to_i})", '1'],
          ["#{l(:status_registered)} (#{user_count_by_status[2].to_i})", '2'],
          ["#{l(:status_locked)} (#{user_count_by_status[3].to_i})", '3']], :group => group},
      'login' => { :type => :string, :order => 7, :group => group},
      'firstname' => { :type => :string, :order => 8, :group => group},
      'lastname' => { :type => :string, :order => 9, :group => group},
      'mail' => { :type => :string, :order => 10, :group => group},
      'easy_user_type' => { :type => :list, :values => [["#{l(:'user.easy_user_type.internal')}", User::EASY_USER_TYPE_INTERNAL],["#{l(:'user.easy_user_type.external')}", User::EASY_USER_TYPE_EXTERNAL]], :order => 11, :group => group},
      'admin' => { :type => :list, :values => [["#{l(:general_text_Yes)}", '1'],["#{l(:general_text_No)}", '0']], :order => 12 , :group => group},
      'easy_lesser_admin' => { :type => :list, :values => [["#{l(:general_text_Yes)}", '1'],["#{l(:general_text_No)}", '0']], :order => 13 , :group => group},
      'easy_system_flag' => { :type => :list, :values => [["#{l(:general_text_Yes)}", '1'],["#{l(:general_text_No)}", '0']], :order => 14 , :group => group},
      'created_on' => { :type => :date_period, :order => 15, :group => group},
      'groups' => {:type => :list, :order => 20, :values => Proc.new{Group.all.collect{|g| [g.lastname, g.id.to_s]}}, :group => group},
      'roles' => {:type => :list, :order => 21, :values => Proc.new{Role.all.collect{|r| [r.name, r.id.to_s]}}, :group => group}
    }
    add_custom_fields_filters(UserCustomField)

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:login, :sortable => "#{User.table_name}.login"),
        EasyQueryColumn.new(:firstname,:sortable => "#{User.table_name}.firstname", :groupable => true),
        EasyQueryColumn.new(:lastname, :sortable => "#{User.table_name}.lastname"),
        EasyQueryColumn.new(:mail, :sortable => "#{User.table_name}.mail"),
        EasyQueryColumn.new(:easy_user_type, :sortable => "#{User.table_name}.easy_user_type", :groupable => true),
        EasyQueryColumn.new(:admin, :sortable => "#{User.table_name}.admin", :groupable => true),
        EasyQueryColumn.new(:easy_lesser_admin, :sortable => "#{User.table_name}.easy_lesser_admin", :groupable => true),
        EasyQueryColumn.new(:cached_group_names, :sortable => "#{User.table_name}.cached_group_names", :groupable => true),
        EasyQueryColumn.new(:easy_system_flag, :sortable => "#{User.table_name}.easy_system_flag", :groupable => true),
        EasyQueryColumn.new(:last_login_on, :sortable => "#{User.table_name}.last_login_on", :groupable => true),
        EasyQueryColumn.new(:created_on, :sortable => "#{User.table_name}.created_on", :groupable => true),
        EasyQueryColumn.new(:easy_global_rating, :sortable => "#{EasyGlobalRating.table_name}.value")
      ]
      @available_columns += UserCustomField.all.collect {|cf| EasyQueryCustomFieldColumn.new(cf)}
      @available_columns_added = true
    end
    @available_columns
  end

  def searchable_columns
    ["#{Principal.table_name}.login", "#{Principal.table_name}.lastname", "#{Principal.table_name}.firstname", "#{Principal.table_name}.mail"]
  end

  def entity
    User
  end

  def get_custom_sql_for_field(field, operator, value)
    sql = ''
    if field =~ /^cf_(\d+)$/
      # custom field
      db_table = CustomValue.table_name
      db_field = 'value'
      sql << "#{User.table_name}.id IN (SELECT #{User.table_name}.id FROM #{User.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Principal' AND #{db_table}.customized_id=#{User.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
      sql << sql_for_field(field, operator, value, db_table, db_field, true) + ')'
    elsif field == 'groups'
      db_table = 'groups_users'
      db_field = 'group_id'
      sql << "#{User.table_name}.id IN (SELECT #{User.table_name}.id FROM #{User.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.user_id=#{User.table_name}.id AND #{sql_for_field(field, operator, value, db_table, 'group_id', true)} WHERE "
      sql << sql_for_field(field, operator, value, db_table, db_field, true) + ')'
    elsif field == 'roles'
      ids = User.includes(:roles).where(sql_for_field(field, operator, value, Role.table_name, :id, true)).collect{|u| u.id.to_s}
      sql << sql_for_field(field, '=', ids, User.table_name, 'id', true)
    end

    return sql
  end

  def default_find_include
    [:easy_global_rating, :members]
  end

  def default_sort_criteria
    User.name_formatter[:order]
  end

  protected

end