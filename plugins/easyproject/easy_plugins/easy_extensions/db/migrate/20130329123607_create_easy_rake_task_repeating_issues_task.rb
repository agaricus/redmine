class CreateEasyRakeTaskRepeatingIssuesTask < ActiveRecord::Migration

  def easy_rake_class
    klass = Module.const_get('EasyRakeTaskRepeatingIssues')
    return klass klass.is_a?(Class)
  rescue NameError
    return EasyRakeTaskRepeatingEntities
  end

  def up
    add_column :issues, :easy_is_repeating, :boolean, :default => false
    add_column :issues, :easy_repeat_settings, :text
    add_column :issues, :easy_next_start, :date

    easy_rake_class.reset_column_information

    t = easy_rake_class.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now)
    t.builtin = 1
    t.save!
  end

  def down
    remove_column :issues, :easy_is_repeating
    remove_column :issues, :easy_repeat_settings
    remove_column :issues, :easy_next_start

    easy_rake_class.all.each do |e|
      e.easy_rake_task_infos.destroy_all
    end
    easy_rake_class.delete_all
  end
end
