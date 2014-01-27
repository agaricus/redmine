class AddEasyExternalId < ActiveRecord::Migration
  def up

    add_column :attachments, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :custom_fields, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :custom_values, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :enumerations, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :documents, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :issues, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :issue_statuses, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :members, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :projects, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :roles, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :time_entries, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :trackers, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :users, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :versions, :easy_external_id, :string, {:null => true, :limit => 255}

  end

  def down

    remove_column :attachments, :easy_external_id
    remove_column :custom_fields, :easy_external_id
    remove_column :custom_values, :easy_external_id
    remove_column :enumerations, :easy_external_id
    remove_column :documents, :easy_external_id
    remove_column :issues, :easy_external_id
    remove_column :issue_statuses, :easy_external_id
    remove_column :members, :easy_external_id
    remove_column :projects, :easy_external_id
    remove_column :roles, :easy_external_id
    remove_column :time_entries, :easy_external_id
    remove_column :trackers, :easy_external_id
    remove_column :users, :easy_external_id
    remove_column :versions, :easy_external_id

  end
end
