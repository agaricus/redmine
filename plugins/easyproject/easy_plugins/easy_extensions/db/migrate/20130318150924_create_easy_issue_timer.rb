class CreateEasyIssueTimer < ActiveRecord::Migration
  def up
    return if table_exists?(:easy_issue_timers)

    EasySetting.create(:name => 'easy_issue_timer_settings', :value => {
      :active => false,
      :round => 0.25,
      :start => {
        :assigned_to_me => true,
        :status_id => nil
        },
      :end => {
        :assigned_to => :author, # or last_solver
        :status_id => nil,
        :done_ratio => 100
      }
      }) if EasySetting.where(:name => :easy_issue_timer_settings).first.nil?

    create_table :easy_issue_timers do |t|
      t.references  :user
      t.references  :issue
      t.datetime    :start
      t.datetime    :end

      t.timestamps
    end

    add_index :easy_issue_timers, [:user_id, :issue_id]
    add_index :easy_issue_timers, [:issue_id, :user_id]

  end

  def down
    EasySetting.where(:name => 'easy_issue_timer_settings').destroy_all
    drop_table :easy_issue_timers
  end
end
