# moved from easy_external_storages migrations:
# => 002_create_easy_external_authentications
# => 004_add_google_columns_to_easy_authentications
# by Ondrej Ezr 8.11.2013
class CreateEasyExternalAuthentications < ActiveRecord::Migration
  def self.up
    unless EasyExternalAuthentication.table_exists?
      create_table :easy_external_authentications do |t|
        t.references :user
        t.string :uid
        t.string :provider
        t.string :access_token
        t.string :access_secret
        t.string :refresh_token
        t.integer :expires_in
        t.datetime :issued_at
        
        t.timestamps
      end
      add_index :easy_external_authentications, :uid
    end
  end

  def self.down
    drop_table :easy_external_authentications
  end
end