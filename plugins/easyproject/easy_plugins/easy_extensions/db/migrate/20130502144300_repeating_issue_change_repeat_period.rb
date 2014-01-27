class RepeatingIssueChangeRepeatPeriod < ActiveRecord::Migration
  
  def easy_rake_class
    klass = Module.const_get('EasyRakeTaskRepeatingIssues')
    return klass klass.is_a?(Class)
  rescue NameError
    return EasyRakeTaskRepeatingEntities
  end

  def up
    repeating_task = easy_rake_class.first
    repeating_task.period = 'hourly'
    repeating_task.save
  end

  def down
    repeating_task = easy_rake_class.first
    repeating_task.period = 'daily'
    repeating_task.save
  end
end
