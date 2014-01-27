class EasyTimeEntryQuery < EasyTimeEntryBaseQuery

  attr_accessor :only_me
  
  def query_after_initialize
    super
    self.display_project_column_if_project_missing = true
    self.display_save_button = false
  end

  def entity_scope
    TimeEntry.non_templates.visible_with_archived
  end
  
  def available_filters
    a = super
    if only_me
      @available_filters.delete('user_id')
    end
    a
  end

end
