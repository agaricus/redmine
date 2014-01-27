class CreateEasySettings < ActiveRecord::Migration
  def self.up
    create_table :easy_settings do |t|
      t.string :name
      t.text :value
      t.integer :project_id
    end
  end

  def self.down
    drop_table :easy_settings
  end
end