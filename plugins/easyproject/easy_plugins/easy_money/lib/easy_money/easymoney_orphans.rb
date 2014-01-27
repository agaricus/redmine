require 'easy_extensions/easyproject_maintenance'

module EasyExtensions
  class EasyMoneyOrphans < Orphans

    def delete_orphans
      return unless EasyMoneyExpectedExpense.table_exists? || EasyMoneyExpectedHours.table_exists? || EasyMoneyExpectedPayrollExpense.table_exists? ||
        EasyMoneyExpectedRevenue.table_exists? || EasyMoneyOtherExpense.table_exists? || EasyMoneyOtherRevenue.table_exists? ||
        EasyMoneyRate.table_exists? || EasyMoneyRatePriority.table_exists? || EasyMoneySettings.table_exists?

      CustomValue.find(:all, :joins => "LEFT JOIN #{EasyMoneyOtherExpense.table_name} ON #{EasyMoneyOtherExpense.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{EasyMoneyOtherExpense.table_name}.id IS NULL AND customized_type = 'EasyMoneyOtherExpense'").each{|cv| cv.delete}
      CustomValue.find(:all, :joins => "LEFT JOIN #{EasyMoneyOtherRevenue.table_name} ON #{EasyMoneyOtherRevenue.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{EasyMoneyOtherRevenue.table_name}.id IS NULL AND customized_type = 'EasyMoneyOtherRevenue'").each{|cv| cv.delete}
      EasyMoneyExpectedExpense.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyExpectedExpense.table_name}.entity_id", :conditions => "#{Project.table_name}.id IS NULL AND #{EasyMoneyExpectedExpense.table_name}.entity_type = 'Project'").each{|emee| emee.delete}
      EasyMoneyExpectedHours.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyExpectedHours.table_name}.entity_id", :conditions => "#{Project.table_name}.id IS NULL AND #{EasyMoneyExpectedHours.table_name}.entity_type = 'Project'").each{|emeh| emeh.delete}
      EasyMoneyExpectedPayrollExpense.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyExpectedPayrollExpense.table_name}.entity_id", :conditions => "#{Project.table_name}.id IS NULL AND #{EasyMoneyExpectedPayrollExpense.table_name}.entity_type = 'Project'").each{|emepe| emepe.delete}
      EasyMoneyExpectedRevenue.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyExpectedRevenue.table_name}.entity_id", :conditions => "#{Project.table_name}.id IS NULL AND #{EasyMoneyExpectedRevenue.table_name}.entity_type = 'Project'").each{|emer| emer.delete}
      EasyMoneyOtherExpense.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyOtherExpense.table_name}.entity_id", :conditions => "#{Project.table_name}.id IS NULL AND #{EasyMoneyOtherExpense.table_name}.entity_type = 'Project'").each{|emoe| emoe.delete}
      EasyMoneyOtherRevenue.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyOtherRevenue.table_name}.entity_id", :conditions => "#{Project.table_name}.id IS NULL AND #{EasyMoneyOtherRevenue.table_name}.entity_type = 'Project'").each{|emor| emor.delete}
      EasyMoneyRate.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyRate.table_name}.project_id", :conditions => "#{EasyMoneyRate.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|emr| emr.delete}
      entity_type = EasyMoneyRate.all.collect(&:entity_type).uniq
      if entity_type.include?('TimeEntryActivity')
        EasyMoneyRate.find(:all, :joins => "LEFT JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'TimeEntryActivity' AND #{Enumeration.table_name}.id IS NULL").each{|emr| emr.delete}
        EasyMoneyRate.find(:all, :joins => "INNER JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'TimeEntryActivity' AND #{EasyMoneyRate.table_name}.project_id IS NOT NULL AND #{EasyMoneyRate.table_name}.project_id != #{Enumeration.table_name}.project_id").each{|emr| emr.delete}  
      elsif entity_type.include?('Enumeration')
        EasyMoneyRate.find(:all, :joins => "LEFT JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'Enumeration' AND #{Enumeration.table_name}.id IS NULL").each{|emr| emr.delete}
        EasyMoneyRate.find(:all, :joins => "INNER JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'Enumeration' AND #{EasyMoneyRate.table_name}.project_id IS NOT NULL AND #{EasyMoneyRate.table_name}.project_id != #{Enumeration.table_name}.project_id").each{|emr| emr.delete}
      end
      if entity_type.include?('User')
        EasyMoneyRate.find(:all, :joins => "LEFT JOIN #{User.table_name} ON #{User.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'User' AND #{User.table_name}.id IS NULL").each{|emr| emr.delete}
      elsif entity_type.include?('Principal')
        EasyMoneyRate.find(:all, :joins => "LEFT JOIN #{User.table_name} ON #{User.table_name}.id = #{EasyMoneyRate.table_name}.entity_id", :conditions => "#{EasyMoneyRate.table_name}.entity_type = 'User' AND #{User.table_name}.id IS NULL").each{|emr| emr.delete}
      end
      EasyMoneyRatePriority.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneyRatePriority.table_name}.project_id", :conditions => "#{EasyMoneyRatePriority.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|emr| emr.delete}
      EasyMoneySettings.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EasyMoneySettings.table_name}.project_id", :conditions => "#{EasyMoneySettings.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|ems| ems.delete}
    end

  end
end