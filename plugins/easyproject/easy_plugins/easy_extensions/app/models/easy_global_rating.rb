class EasyGlobalRating < ActiveRecord::Base
  
  belongs_to :customized, :polymorphic => true
  
  validates_presence_of :customized
  
end