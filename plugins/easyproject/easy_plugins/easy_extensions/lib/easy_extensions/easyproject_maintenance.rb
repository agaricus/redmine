module EasyExtensions
  class Orphans

    @@registered_subclasses = []

    def self.map(&block)
      yield self
    end

    def self.register_plugin(orphans_class)
      raise ArgumentError, 'The orphans_class has to be child of EasyExtensions::Orphans class' unless orphans_class.is_a?(EasyExtensions::Orphans)
      @@registered_subclasses << orphans_class unless @@registered_subclasses.include?(orphans_class)
    end

    def delete_orphans
      raise NotImplementedError
    end

    def self.delete_all_orphans
      user = User.current
      User.current = User.find(:first, :conditions => {:admin => true})
      @@registered_subclasses.each do |orphans_class|
        orphans_class.delete_orphans
      end
      User.current = user
    end

  end

  class EasyExtensionsOrphans < Orphans

    def delete_orphans
      Board.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Board.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|b| b.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM custom_fields_projects WHERE custom_field_id NOT IN (SELECT id FROM #{CustomField.table_name})")
      ActiveRecord::Base.connection.execute("DELETE FROM custom_fields_projects WHERE NOT EXISTS (SELECT #{Project.table_name}.id FROM #{Project.table_name} WHERE #{Project.table_name}.id = custom_fields_projects.project_id)")
      CustomValue.find(:all, :joins => "LEFT JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{Enumeration.table_name}.id IS NULL AND customized_type = 'Enumeration'").each{|cv| cv.delete}
      CustomValue.find(:all, :joins => "LEFT JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{Issue.table_name}.id IS NULL AND customized_type = 'Issue'").each{|cv| cv.delete}
      CustomValue.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{Project.table_name}.id IS NULL AND customized_type = 'Project'").each{|cv| cv.delete}
      CustomValue.find(:all, :joins => "LEFT JOIN #{User.table_name} ON #{User.table_name}.id = #{CustomValue.table_name}.customized_id", :conditions => "#{User.table_name}.id IS NULL AND customized_type = 'Principal'").each{|cv| cv.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM #{CustomValue.table_name} LEFT JOIN #{CustomField.table_name} ON #{CustomValue.table_name}.custom_field_id = #{CustomField.table_name}.id WHERE #{CustomValue.table_name}.customized_type = 'Project' AND #{CustomField.table_name}.is_for_all = #{ActiveRecord::Base.connection.quoted_false} AND NOT EXISTS (SELECT * FROM custom_fields_projects cfp WHERE cfp.project_id = #{CustomValue.table_name}.customized_id AND cfp.custom_field_id = #{CustomValue.table_name}.custom_field_id)")
      Document.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Document.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|d| d.delete}
      Attachment.find(:all, :joins => "LEFT JOIN #{Document.table_name} ON #{Document.table_name}.id = #{Attachment.table_name}.container_id", :conditions => "#{Attachment.table_name}.container_type = 'Document' AND #{Document.table_name}.id IS NULL").each{|a| a.delete}
      EnabledModule.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{EnabledModule.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|em| em.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM #{Enumeration.table_name} WHERE NOT EXISTS (SELECT #{Project.table_name}.id FROM #{Project.table_name} WHERE #{Project.table_name}.id = #{Enumeration.table_name}.project_id) AND #{Enumeration.table_name}.project_id IS NOT NULL")
      Issue.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Issue.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|i| i.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM #{IssueCategory.table_name} WHERE NOT EXISTS (SELECT #{Project.table_name}.id FROM #{Project.table_name} WHERE #{Project.table_name}.id = #{IssueCategory.table_name}.project_id)")
      ActiveRecord::Base.connection.execute("DELETE FROM #{Journal.table_name} WHERE NOT EXISTS (SELECT #{Issue.table_name}.id FROM #{Issue.table_name} WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id) AND #{Journal.table_name}.journalized_type = 'Issue'")
      ActiveRecord::Base.connection.execute("DELETE FROM #{JournalDetail.table_name} WHERE NOT EXISTS (SELECT #{Journal.table_name}.id FROM #{Journal.table_name} WHERE #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id)")
      Member.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Member.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|m| m.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM #{MemberRole.table_name} WHERE NOT EXISTS (SELECT #{Member.table_name}.id FROM #{Member.table_name} WHERE #{Member.table_name}.id = #{MemberRole.table_name}.member_id)")
      News.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{News.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|n| n.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM projects_trackers WHERE NOT EXISTS (SELECT #{Project.table_name}.id FROM #{Project.table_name} WHERE #{Project.table_name}.id = projects_trackers.project_id)")
      Query.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Query.table_name}.project_id", :conditions => "#{Query.table_name}.project_id IS NOT NULL AND #{Project.table_name}.id IS NULL").each{|r| r.delete}
      Repository.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Repository.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|r| r.delete}
      TimeEntry.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{TimeEntry.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|te| te.delete}
      Version.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Version.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|v| v.delete}
      Wiki.find(:all, :joins => "LEFT JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Wiki.table_name}.project_id", :conditions => "#{Project.table_name}.id IS NULL").each{|w| w.delete}
      ActiveRecord::Base.connection.execute("DELETE FROM #{Watcher.table_name} WHERE NOT EXISTS (SELECT #{Issue.table_name}.id FROM #{Issue.table_name} WHERE #{Issue.table_name}.id = #{Watcher.table_name}.watchable_id) AND #{Watcher.table_name}.watchable_type = 'Issue';")
      ActiveRecord::Base.connection.execute("DELETE FROM #{Watcher.table_name} WHERE NOT EXISTS (SELECT #{Project.table_name}.id FROM #{Project.table_name} WHERE #{Project.table_name}.id = #{Watcher.table_name}.watchable_id) AND #{Watcher.table_name}.watchable_type = 'Project';")
      ActiveRecord::Base.connection.execute("DELETE FROM #{CustomValue.table_name} WHERE customized_type = 'Enumeration' AND customized_id NOT IN (SELECT id FROM #{Enumeration.table_name});")

      # Easy pages
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageAvailableModule.table_name} WHERE NOT EXISTS (SELECT #{EasyPageModule.table_name}.id FROM #{EasyPageModule.table_name} WHERE #{EasyPageModule.table_name}.id = #{EasyPageAvailableModule.table_name}.easy_page_modules_id);")
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageAvailableZone.table_name} WHERE NOT EXISTS (SELECT #{EasyPageZone.table_name}.id FROM #{EasyPageZone.table_name} WHERE #{EasyPageZone.table_name}.id = #{EasyPageAvailableZone.table_name}.easy_page_zones_id);")
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageZoneModule.table_name} WHERE NOT EXISTS (SELECT #{EasyPageAvailableModule.table_name}.id FROM #{EasyPageAvailableModule.table_name} WHERE #{EasyPageAvailableModule.table_name}.id = #{EasyPageZoneModule.table_name}.easy_page_available_modules_id);")
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageZoneModule.table_name} WHERE NOT EXISTS (SELECT #{EasyPageAvailableZone.table_name}.id FROM #{EasyPageAvailableZone.table_name} WHERE #{EasyPageAvailableZone.table_name}.id = #{EasyPageZoneModule.table_name}.easy_page_available_zones_id);")
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageTemplateModule.table_name} WHERE NOT EXISTS (SELECT #{EasyPageAvailableModule.table_name}.id FROM #{EasyPageAvailableModule.table_name} WHERE #{EasyPageAvailableModule.table_name}.id = #{EasyPageTemplateModule.table_name}.easy_page_available_modules_id);")
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageTemplateModule.table_name} WHERE NOT EXISTS (SELECT #{EasyPageAvailableZone.table_name}.id FROM #{EasyPageAvailableZone.table_name} WHERE #{EasyPageAvailableZone.table_name}.id = #{EasyPageTemplateModule.table_name}.easy_page_available_zones_id);")
      ActiveRecord::Base.connection.execute("DELETE FROM #{EasyPageModule.table_name} WHERE NOT EXISTS (SELECT #{EasyPageAvailableModule.table_name}.id FROM #{EasyPageAvailableModule.table_name} WHERE #{EasyPageAvailableModule.table_name}.easy_page_modules_id = #{EasyPageModule.table_name}.id);")
    end

  end

end
