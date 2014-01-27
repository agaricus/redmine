class EasySlidingPanelsLocation < ActiveRecord::Base
  belongs_to :user

  validates :name, :zone, :presence => true

end
