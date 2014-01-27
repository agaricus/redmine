require 'easy_extensions/easyproject_maintenance'

module EasyExtensions
  class EasyUserAllocationsOrphans < Orphans

    def delete_orphans
      return unless EasyUserAllocation.table_exists?
      EasyUserAllocation.includes(:issue).where(:issues => {:id => nil}).destroy_all
    end

  end
end
