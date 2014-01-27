class EasyMoneyRatePriority < ActiveRecord::Base
  self.table_name = 'easy_money_rate_priorities'
  
  default_scope :order => "#{EasyMoneyRatePriority.table_name}.position ASC"

  belongs_to :project, :class_name => "Project", :foreign_key => 'project_id'
  belongs_to :rate_type, :class_name => "EasyMoneyRateType", :foreign_key => 'rate_type_id'

  acts_as_list

  scope :rate_priorities_by_project, lambda { |project| where("#{EasyMoneyRatePriority.table_name}.project_id " + (project.nil? ? "IS NULL" : "=#{project.id}")) } do
    def copy_to(project)
      project_id = project.is_a?(Project) ? project.id : project
      return if project_id.nil?
      each do |rate_priority|
        EasyMoneyRatePriority.create(:project_id => project_id, :rate_type_id => rate_priority.rate_type_id, :entity_type => rate_priority.entity_type) if EasyMoneyRatePriority.find_by_project_id_and_rate_type_id_and_entity_type(project_id, rate_priority.rate_type_id, rate_priority.entity_type).nil?
      end
    end
  end

  scope :rate_priorities_by_rate_type_and_project, lambda { |rate_type_id, project_id| where("#{EasyMoneyRatePriority.table_name}.rate_type_id = #{rate_type_id} AND #{EasyMoneyRatePriority.table_name}.project_id " + (project_id.blank? ? "IS NULL" : "=#{project_id}"))}

  # acts_as_list :scope => ...
  def scope_condition
    ("rate_type_id = #{self.rate_type_id} AND project_id " + (self.project_id.blank? ? "IS NULL" : "= #{self.project_id}" ) )
  end

end
