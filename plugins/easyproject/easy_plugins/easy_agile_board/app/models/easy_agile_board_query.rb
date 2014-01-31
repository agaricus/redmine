class EasyAgileBoardQuery < EasyIssueQuery

  def query_after_initialize
    super
    self.display_filter_columns_on_index  = false
    self.display_filter_group_by_on_index = false
    self.display_filter_sort_on_index     = false
    self.display_filter_columns_on_edit   = false
    self.display_filter_group_by_on_edit  = false
    self.display_filter_sort_on_edit      = false
    self.display_filter_fullscreen_button = false
    self.display_save_button              = false
    self.export_formats                   = {}
  end

end
