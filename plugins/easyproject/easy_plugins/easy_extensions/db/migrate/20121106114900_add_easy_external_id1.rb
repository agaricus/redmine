class AddEasyExternalId1 < ActiveRecord::Migration
  def up

    add_column :attachment_versions, :easy_external_id, :string, {:null => true, :limit => 255}

  end

  def down

    remove_column :attachment_versions, :easy_external_id

  end
end
