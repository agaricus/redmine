class EasySetting < ActiveRecord::Base

  belongs_to :project

  serialize :value

  validates :name, :presence => true

  after_save :change_settings

  def self.boolean_keys
    [:project_calculate_start_date, :project_calculate_due_date, :timelog_comment_editor_enabled,
      :time_entry_spent_on_at_issue_update_enabled, :commit_logtime_enabled, :project_fixed_activity,
      :enable_activity_roles, :show_issue_id, :commit_cross_project_ref, :issue_recalculate_attributes,
      :quick_jump_to_an_issue, :use_easy_cache, :avatar_enabled, :show_personal_statement, :show_bulk_time_entry,
      :enable_private_issues, :use_personal_theme, :display_issue_relations_on_new_form, :milestone_effective_date_from_issue_due_date,
      :allow_log_time_to_closed_issue, :project_display_identifiers, :issue_set_done_after_close, :allow_repeating_issues,
      :just_one_issue_mail, :required_issue_id_at_time_entry, :close_subtask_after_parent, :show_time_entry_range_select,
      :easy_contact_toolbar_is_enabled, :issue_private_note_as_default, :show_easy_resource_booking
    ]
  end

  def self.internal_cache
    Thread.current[:easy_settings_internal_cache] ||= Hash.new
  end

  def self.copy_project_settings(setting_name, source_project_id, target_project_id)
    source = EasySetting.where(:name => setting_name, :project_id => source_project_id).first
    target = EasySetting.where(:name => setting_name, :project_id => target_project_id).first

    if source.nil? && !target.nil?
      target.destroy
    elsif !source.nil? && target.nil?
      EasySetting.create(:name => setting_name, :project_id => target_project_id, :value => source.value)
    elsif !source.nil? && !target.nil? && target.value != source.value
      target.value = source.value
      target.save
    end
  end

  def self.value(key, project_or_project_id = nil)
    if project_or_project_id.is_a?(Project)
      project_id = project_or_project_id.id
    elsif !project_or_project_id.nil?
      project_id = project_or_project_id.to_i
    else
      project_id = nil
    end

    key = key.to_s

    ensure_key_in_internal_cache(key, project_id)

    unless internal_cache.key?(key)
      logger.error("The key (#{key}) doesn't exists in EasySetting collection!") if logger
      return nil
    end

    val = internal_cache[key][project_id]
    val = internal_cache[key][nil] if val.nil?
    val
  end

  def self.ensure_key_in_internal_cache(key, project_id = nil)
    if !internal_cache.key?(key)
      internal_cache[key] = Hash.new
    end
    if !internal_cache[key].key?(nil)
      internal_cache[key][nil] = EasySetting.where(:name => key, :project_id => nil).pluck(:value).first
    end
    if !project_id.nil? && !internal_cache[key].key?(project_id.to_i)
      internal_cache[key][project_id.to_i] = EasySetting.where(:name => key, :project_id => project_id).pluck(:value).first
    end
  end

  def self.delete_key(key, project_or_project_id)
    if project_or_project_id.is_a?(Project)
      project_id = project_or_project_id.id
    elsif !project_or_project_id.nil?
      project_id = project_or_project_id.to_i
    else
      project_id = nil
    end
    return if project_id.nil?
    EasySetting.where(:name => key, :project_id => project_id).delete_all
    internal_cache[key].delete(project_id) if internal_cache.key?(key)
  end

  private

  def change_settings
    self.class.internal_cache[self.name.to_s] ||= Hash.new
    self.class.internal_cache[self.name.to_s][self.project_id] = EasySetting.where(:name => self.name, :project_id => self.project_id).pluck(:value).first
  end

end
