class EasyPageUserTab < ActiveRecord::Base
  belongs_to :page_definition, :class_name => "EasyPage", :foreign_key => 'page_id'
  belongs_to :user

  acts_as_list

  scope :page_tabs, lambda { |page, user_id, entity_id| {
      :conditions => EasyPageUserTab.tab_condition(page.id, user_id, entity_id),
      :order => "#{EasyPageUserTab.table_name}.position"}}

  def self.tab_condition(page_id, user_id, entity_id)
    cond = "#{EasyPageUserTab.table_name}.page_id = #{page_id}"
    cond << (user_id.blank? ? " AND #{EasyPageUserTab.table_name}.user_id IS NULL" :  " AND #{EasyPageUserTab.table_name}.user_id = #{user_id}")
    cond << (entity_id.blank? ?  " AND #{EasyPageUserTab.table_name}.entity_id IS NULL" :  " AND #{EasyPageUserTab.table_name}.entity_id = #{entity_id}")
    cond
  end

  private

  # Overrides acts_as_list - scope_condition
  def scope_condition
    EasyPageUserTab.tab_condition(self.page_id, self.user_id, self.entity_id)
  end

end