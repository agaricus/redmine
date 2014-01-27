class FillAvatarsCache < ActiveRecord::Migration
  def up
    User.reset_column_information
    User.all.each do |user|
      att = user.attachments.first
      next unless att
      next unless File.exist?(att.diskfile)

      user.easy_avatar = att.disk_filename
      user.save
    end
  end

  def down
  end
end
