class EasyRakeTaskInfoDetail < ActiveRecord::Base

  belongs_to :easy_rake_task_info
  belongs_to :entity, :polymorphic => true
  belongs_to :reference, :polymorphic => true

  acts_as_attachable

  def project
    nil # attachment workaround
  end

  def attachments_visible?(user)(user=User.current)
    true  # attachment workaround
  end

  # To override!
  def detail_url(task = nil)
    {}
  end

  # To override!
  def caption
    ''
  end

end
