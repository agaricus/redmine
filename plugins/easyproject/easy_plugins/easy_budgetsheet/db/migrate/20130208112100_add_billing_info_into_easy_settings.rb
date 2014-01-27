class AddBillingInfoIntoEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'show_billable_things', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'show_billable_things').destroy_all
  end
end
