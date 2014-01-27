class EasyUserReadEntity < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :entity, :polymorphic => true

  after_initialize :default_values
  
  def default_values
    self.read_on ||= Time.now
  end

end