class CreateEasyResourceAvailability < ActiveRecord::Migration
  def self.up
    create_table :easy_resource_availabilities do |t|
      t.column :easy_page_zone_module_uuid, :string, {:null => false}
      t.column :name, :string, {:null => false}
      t.column :description, :text, {:null => true}
      t.column :author_id, :integer, {:null => false}
      t.column :date, :date, {:null => false}
      t.column :hour, :integer, {:null => false}
      t.timestamps
    end

    add_index :easy_resource_availabilities, [:easy_page_zone_module_uuid], :uniq => true, :name => "index_easy_resource_av_on_easy_pzmu"
    add_index :easy_resource_availabilities, [:author_id]
  end

  def self.down
    drop_table :easy_resource_availabilities
  end
end