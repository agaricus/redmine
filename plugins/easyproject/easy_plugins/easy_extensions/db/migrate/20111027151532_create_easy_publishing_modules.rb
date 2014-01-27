class CreateEasyPublishingModules < ActiveRecord::Migration
  def self.up
    create_table :easy_publishing_modules do |t|
      t.column :name, :string, { :null => false, :limit => 255, :default => '' }
    end
    
    EasyPublishingModule.create :name => 'contact'
    EasyPublishingModule.create :name => 'info'
    EasyPublishingModule.create :name => 'help'
  end

  def self.down
    drop_table :easy_publishing_modules
  end
end
