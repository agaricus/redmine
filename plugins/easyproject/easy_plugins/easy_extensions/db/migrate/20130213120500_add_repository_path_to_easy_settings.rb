class AddRepositoryPathToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'git_repository_path', :value => 'git_repositories')
  end
  def self.down
    EasySetting.where(:name => 'git_repository_path').destroy_all
  end
end
