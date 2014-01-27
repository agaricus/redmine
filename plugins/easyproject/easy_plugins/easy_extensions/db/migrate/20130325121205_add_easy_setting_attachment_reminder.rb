# encoding: utf-8
class AddEasySettingAttachmentReminder < ActiveRecord::Migration
  def up
    return if EasySetting.where(:name => 'attachment_reminder_words').exists?
    
    EasySetting.create :name => 'attachment_reminder_words', :value => "attachment?,attach??\npříloh?;přilož*"
  end

  def down
    EasySetting.where(:name => 'attachment_reminder_words').destroy_all
  end
end
