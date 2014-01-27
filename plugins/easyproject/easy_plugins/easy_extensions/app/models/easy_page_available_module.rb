class EasyPageAvailableModule < ActiveRecord::Base
  self.table_name = 'easy_page_available_modules'

  belongs_to :page_definition, :class_name => "EasyPage", :foreign_key => 'easy_pages_id'
  belongs_to :module_definition, :class_name => "EasyPageModule", :foreign_key => 'easy_page_modules_id'
  has_many :all_modules, :class_name => "EasyPageZoneModule", :foreign_key => 'easy_page_available_modules_id', :dependent => :delete_all
  has_many :all_template_modules, :class_name => "EasyPageTemplateModule", :foreign_key => 'easy_page_available_modules_id', :dependent => :delete_all

  validates :easy_pages_id, :presence => true
  validates :easy_page_modules_id, :presence => true

end