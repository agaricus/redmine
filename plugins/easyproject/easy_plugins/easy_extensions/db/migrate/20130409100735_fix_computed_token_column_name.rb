class FixComputedTokenColumnName < ActiveRecord::Migration
  def up
    rename_column :custom_fields, :computed_token, :easy_computed_token
    [CustomField, DocumentCategoryCustomField, GroupCustomField, IssueCustomField,
      IssuePriorityCustomField, ProjectCustomField, TimeEntryActivityCustomField,
      TimeEntryCustomField, UserCustomField, VersionCustomField].
      each {|cf_class| cf_class.reset_column_information }
  end

  def down
    rename_column :custom_fields, :easy_computed_token, :computed_token
  end
end
