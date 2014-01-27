class AddEasyVersionCategoryToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :easy_version_category_id , :integer
  end

  def self.down
    remove_column :versions, :easy_version_category_id
  end
end
