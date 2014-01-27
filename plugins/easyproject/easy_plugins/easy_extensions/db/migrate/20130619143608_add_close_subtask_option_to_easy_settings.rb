class AddCloseSubtaskOptionToEasySettings < ActiveRecord::Migration
  def change
    EasySetting.create(:name => 'close_subtask_after_parent', :value => false)
  end
end
