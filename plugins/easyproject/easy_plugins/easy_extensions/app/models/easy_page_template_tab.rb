class EasyPageTemplateTab < ActiveRecord::Base
  belongs_to :page_template_definition, :class_name => "EasyPageTemplate", :foreign_key => 'page_template_id'

  acts_as_list

  scope :page_template_tabs, lambda { |page_template, entity_id| {
      :conditions => EasyPageTemplateTab.tab_condition(page_template.id, entity_id),
      :order => "#{EasyPageTemplateTab.table_name}.position"}}

  def self.tab_condition(page_template_id, entity_id)
    cond = "#{EasyPageTemplateTab.table_name}.page_template_id = #{page_template_id}"
    cond << (entity_id.blank? ?  " AND #{EasyPageTemplateTab.table_name}.entity_id IS NULL" :  " AND #{EasyPageTemplateTab.table_name}.entity_id = #{entity_id}")
    cond
  end

  private

  # Overrides acts_as_list - scope_condition
  def scope_condition
    EasyPageTemplateTab.tab_condition(self.page_template_id, self.entity_id)
  end

end