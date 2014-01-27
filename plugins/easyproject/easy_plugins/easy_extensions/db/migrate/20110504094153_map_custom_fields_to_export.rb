class MapCustomFieldsToExport < ActiveRecord::Migration
  def self.up
    create_table :custom_field_mappings, :force => true do |t|
      t.column :custom_field_id, :integer, { :null => false }
      t.column :format_type, :string, { :null => false, :limit => 255 }
      t.column :group_name, :string, { :null => true, :limit => 255 } # Prefix  like ADR or N ..
      t.column :name, :string, {:null => false, :limit => 255 } # specify value or name of method in Vpim::Vcard
    end
  end

  def self.down
    drop_table :custom_field_mapping
  end
end
