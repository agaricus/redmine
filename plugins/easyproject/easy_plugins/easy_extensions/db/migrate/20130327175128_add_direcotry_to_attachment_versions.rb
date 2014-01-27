class AddDirecotryToAttachmentVersions < ActiveRecord::Migration
  def change
    add_column(:attachment_versions, :disk_directory, :string) unless column_exists?(:attachment_versions, :disk_directory)
  end
end
