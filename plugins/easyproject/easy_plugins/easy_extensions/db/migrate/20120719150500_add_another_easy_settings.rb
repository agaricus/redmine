class AddAnotherEasySettings < ActiveRecord::Migration
  def up
    EasySetting.create(:name => 'commit_cross_project_ref', :value => Setting.commit_cross_project_ref == '1')
  end

  def down
    EasySetting.where(:name => 'commit_cross_project_ref').destroy_all
  end
end
