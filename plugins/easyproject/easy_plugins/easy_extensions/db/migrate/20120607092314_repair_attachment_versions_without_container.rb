class RepairAttachmentVersionsWithoutContainer < ActiveRecord::Migration
  def up
    Attachment::Version.where(:container_id => nil).each do |version|
      version.container = version.attachment.container
      version.save
    end
  end

  def down
  end
end
