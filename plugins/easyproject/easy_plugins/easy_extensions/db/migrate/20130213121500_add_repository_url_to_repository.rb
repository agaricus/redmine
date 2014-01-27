class AddRepositoryUrlToRepository < ActiveRecord::Migration
  def self.up
    add_column :repositories, :easy_repository_url, :string, {:null => true}
  end
  def self.down
    remove_column :repositories, :easy_repository_url
  end
end
