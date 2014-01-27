class AddEasySettingShowPersonalStatementAndShowBulkTimeEntry < ActiveRecord::Migration

  def self.up
    EasySetting.create :name => 'show_personal_statement', :value => '1'
    EasySetting.create :name => 'show_bulk_time_entry', :value => '1'
  end

  def self.down
    EasySetting.where(:name => 'show_personal_statement').destroy_all
    EasySetting.where(:name => 'show_bulk_time_entry').destroy_all
  end
end