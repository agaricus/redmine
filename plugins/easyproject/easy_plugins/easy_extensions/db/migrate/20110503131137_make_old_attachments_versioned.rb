# In old attachments system make versions if attachment in entity have more same filename of file.
class MakeOldAttachmentsVersioned < ActiveRecord::Migration
  def self.up

    say_with_time 'Please wait. Making attachments to versioned attachments. This will take a moment...' do

      attached_versions = Hash.new {|hash,key| hash[key] = Hash.new}
      journals_to_update = Hash.new

      Attachment.transaction do
        Attachment.order(:created_on).all.each do |att|
          if attached_versions["#{att.container_type}-#{att.container_id}"][att.filename]
            attributes = att.attributes
            attributes.delete(:id); attributes.delete(:version)
            attached_versions["#{att.container_type}-#{att.container_id}"][att.filename].update_attributes(attributes)
            # if exists journals they must be update link to new versions
            detail = JournalDetail.joins(:journal).where(:journals => {:journalized_type => att.container_type, :journalized_id => att.container_id}, :property => 'attachment', :prop_key => att.id.to_s).first

            if detail && attached_versions["#{att.container_type}-#{att.container_id}"][att.filename] && (v = attached_versions["#{att.container_type}-#{att.container_id}"][att.filename].versions.last)
              journals_to_update[detail.id] = v.id.to_s
              #detail.update_attribute(:prop_key, v.id.to_s)

              Attachment::Version.where(:attachment_id => att.id).delete_all
              att.delete
            end
          else
            attached_versions["#{att.container_type}-#{att.container_id}"][att.filename] = att
          end
        end
      end
      # update journals
      JournalDetail.transaction do
        journals_to_update.each do |j,id|
          detail = JournalDetail.find(j)
          detail.prop_key = id
          detail.save!
        end
      end
    end

  end

  def self.down
  end
end
