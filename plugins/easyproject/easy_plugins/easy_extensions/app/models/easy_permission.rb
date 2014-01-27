class EasyPermission < ActiveRecord::Base

  belongs_to :entity, :polymorphic => true

  serialize :user_list, Array
  serialize :role_list, Array
  serialize :permissions, Hash
  
end