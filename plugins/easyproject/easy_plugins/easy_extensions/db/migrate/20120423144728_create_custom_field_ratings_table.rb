class CreateCustomFieldRatingsTable < ActiveRecord::Migration
  def self.up
    create_table :easy_custom_field_ratings do |t|
      t.references :custom_value, :null => false
      t.integer :rating
      t.text :description
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :easy_custom_field_ratings
  end
end