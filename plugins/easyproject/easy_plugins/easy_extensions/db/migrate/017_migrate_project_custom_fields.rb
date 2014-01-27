class MigrateProjectCustomFields < ActiveRecord::Migration
  def self.up
    CustomValue.where(:customized_type => 'Project').includes(:customized).select([:customized_id, :custom_field_id, :customized_type]).group_by(&:customized).each do |project, cvs|
      pcfs = (project.project_custom_field_ids + cvs.map(&:custom_field_id)).uniq
      project.project_custom_field_ids = pcfs
    end
  end

  def self.down
  end
end
