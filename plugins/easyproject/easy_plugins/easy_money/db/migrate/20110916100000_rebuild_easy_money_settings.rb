#require 'easy_extensions/easyproject_maintenance'

class RebuildEasyMoneySettings < ActiveRecord::Migration
  def self.up

#    EasyExtensions::Orphans.delete_all_orphans
#    EasyMoneyRate.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyRate.table_name}.project_id", :conditions => "#{EasyMoneyRate.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|emr| emr.delete}
#    EasyMoneyRatePriority.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyRatePriority.table_name}.project_id", :conditions => "#{EasyMoneyRatePriority.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|emr| emr.delete}
#    EasyMoneySettings.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneySettings.table_name}.project_id", :conditions => "#{EasyMoneySettings.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|ems| ems.delete}
#
#    EasyMoneySettings.find(:all, :conditions => 'project_id is not null').collect(&:project_id).uniq.each do |project_id|
#      project = Project.find(project_id)
#
#      expected = 0
#      EasyMoneySettings.find(:all, :conditions => {:project_id => project.id}).each do |settings|
#        case settings.name
#        when 'expected_revenue'
#          expected += settings.value.to_i
#        when 'expected_expense'
#          expected += settings.value.to_i
#        when 'expected_payroll_expense'
#          expected += settings.value.to_i
#        when 'expected_hours'
#          expected += settings.value.to_i
#        else
#          next
#        end
#      end
#
#      if expected > 0
#        EasyMoneySettings.create(:name => 'expected_visibility', :project_id => project.id, :value => '1')
#      else
#        EasyMoneySettings.create(:name => 'expected_visibility', :project_id => project.id, :value => '0')
#      end
#
#      EasyMoneySettings.create(:name => 'revenues_type', :project_id => project.id, :value => 'list')
#      EasyMoneySettings.create(:name => 'expenses_type', :project_id => project.id, :value => 'list')
#      EasyMoneySettings.create(:name => 'expected_payroll_expense_type', :project_id => project.id, :value => 'amount')
#    end
#
#    EasyMoneySettings.create(:name => 'expected_visibility', :project_id => nil, :value => '1')
#    EasyMoneySettings.create(:name => 'revenues_type', :project_id => nil, :value => 'list')
#    EasyMoneySettings.create(:name => 'expenses_type', :project_id => nil, :value => 'list')
#    EasyMoneySettings.create(:name => 'expected_payroll_expense_type', :project_id => nil, :value => 'amount')
#
#    EasyMoneySettings.find(:all, :conditions => {:name => 'expected_revenue'}).each{|s| s.destroy}
#    EasyMoneySettings.find(:all, :conditions => {:name => 'expected_expense'}).each{|s| s.destroy}
#    EasyMoneySettings.find(:all, :conditions => {:name => 'expected_payroll_expense'}).each{|s| s.destroy}
#    EasyMoneySettings.find(:all, :conditions => {:name => 'expected_hours'}).each{|s| s.destroy}

  end  

  def self.down
  end

end
