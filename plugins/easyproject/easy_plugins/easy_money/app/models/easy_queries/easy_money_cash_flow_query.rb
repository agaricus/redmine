class EasyMoneyCashFlowQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_money
  end

  def query_after_initialize
    super
    self.display_project_column_if_project_missing = false
    self.export_formats = ActiveSupport::OrderedHash.new
    self.display_save_button, self.display_filter_fullscreen_button = false, false
    self.display_filter_sort_on_index, self.display_filter_columns_on_index, self.display_filter_group_by_on_index = false, false, false
  end

  def all_projects
    @all_easy_money_projects ||= Project.visible.non_templates.has_module(:easy_money).select([:id, :name, :easy_level]).all
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    @available_filters = {}

    group_others = l(:label_filter_group_easy_money_project_cache_query)

    @available_filters['id'] = {:type => :list_optional, :order => 1, :values => Proc.new do
        project_values = []
        if User.current.logged?
          project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
        end
        project_values += self.all_projects_values
        project_values
      end, :group => group_others
    }

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:id)
      ]

      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    Project
  end

  def entity_scope
    Project.visible.non_templates.has_module(:easy_money)
  end

  protected

  def sql_for_project_id_field(field, operator, value)
    sql_for_field(field, operator, value, Project.table_name, 'id')
  end

end
