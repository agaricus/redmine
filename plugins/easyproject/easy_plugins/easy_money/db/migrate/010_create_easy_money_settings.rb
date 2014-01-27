class CreateEasyMoneySettings < ActiveRecord::Migration
  def self.up
    create_table :easy_money_settings do |t|
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :project_id, :integer, { :null => true }
      t.column :value, :string, { :null => false, :limit => 255 }
    end
  end

  def self.down
    drop_table :easy_money_settings
  end
end
