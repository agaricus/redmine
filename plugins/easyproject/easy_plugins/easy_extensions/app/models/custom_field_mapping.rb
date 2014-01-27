class CustomFieldMapping < ActiveRecord::Base

  belongs_to :custom_field

  validates :custom_field_id, :name, :presence => true

end
